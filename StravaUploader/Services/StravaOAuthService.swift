import Foundation
import AuthenticationServices

struct StravaOAuthToken: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let expiresIn: Int
    let athleteId: Int
    let tokenType: String
    let scope: String

    var isExpired: Bool {
        Date() >= expiresAt
    }

    var shouldRefresh: Bool {
        Date() >= expiresAt.addingTimeInterval(-3600) // Refresh when less than 1 hour remaining
    }

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case expiresIn = "expires_in"
        case athleteId = "athlete_id"
        case tokenType = "token_type"
        case scope
    }
}

class StravaOAuthService: NSObject, ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var isInitialLoading: Bool = true
    @Published var athlete: Athlete?
    @Published var error: String?

    // Replace with your Strava API credentials
    // Users will need to register their own app at https://www.strava.com/settings/api
    private let clientId: String = "253178"
    private let clientSecret: String = "c3b3dd147c0b43a57ee6b5e946025919be39ace2"

    private let tokenUrl = URL(string: "https://www.strava.com/oauth/token")!
    private let apiBaseUrl = URL(string: "https://www.strava.com/api/v3")!

    private var authSession: ASWebAuthenticationSession?
    private var currentToken: StravaOAuthToken?

    private let userDefaultsTokenKey = "strava_oauth_token"

    override init() {
        super.init()
        loadToken()
    }

    // MARK: - Public Methods

    var isLoggedIn: Bool {
        currentToken != nil && !currentToken!.isExpired
    }

    func login() {
        guard !isLoading else { return }

        let scope = "activity:write,read"
        // Use a custom URL scheme as redirect URI
        // The domain (host) must match what's registered in Strava settings
        // Format: scheme://host/path - ASWebAuthenticationSession intercepts based on scheme
        let redirectUri = "strava-sync://oauth-callback/callback"

        // Build the authorization URL
        var components = URLComponents(string: "https://www.strava.com/oauth/mobile/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope", value: scope)
        ]

        guard let authUrl = components.url else {
            error = "无法构建授权 URL"
            return
        }

        isLoading = true
        error = nil

        authSession = ASWebAuthenticationSession(
            url: authUrl,
            callbackURLScheme: "strava-sync"
        ) { [weak self] callbackUrl, authError in
            DispatchQueue.main.async {
                self?.handleAuthCallback(callbackUrl: callbackUrl, error: authError)
            }
        }

        // For iOS 16+ compatibility
        authSession?.presentationContextProvider = self

        authSession?.start()
    }

    func logout() {
        currentToken = nil
        UserDefaults.standard.removeObject(forKey: userDefaultsTokenKey)
        isAuthenticated = false
        athlete = nil
    }

    func getValidAccessToken() async throws -> String {
        // Check if we need to refresh
        if let token = currentToken, token.shouldRefresh {
            try await refreshToken()
        }

        guard let token = currentToken else {
            throw StravaOAuthError.notAuthenticated
        }

        return token.accessToken
    }

    func loadAthlete() async {
        do {
            let token = try await getValidAccessToken()
            let athleteData = try await fetchAthlete(accessToken: token)

            await MainActor.run {
                self.athlete = athleteData
                self.isAuthenticated = true
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.athlete = nil
                self.isAuthenticated = false
            }
        }
    }

    // MARK: - Private Methods

    private func handleAuthCallback(callbackUrl: URL?, error: Error?) {
        isLoading = false

        if let error = error {
            if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                self.error = "用户取消了登录"
            } else {
                self.error = "授权失败: \(error.localizedDescription)"
            }
            return
        }

        guard let callbackUrl = callbackUrl else {
            self.error = "未收到授权回调"
            return
        }

        print("[DEBUG] Callback URL: \(callbackUrl)")

        // Parse the authorization code from the callback URL
        // For localhost redirect, the code is in the query string
        guard let components = URLComponents(url: callbackUrl, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            self.error = "无法解析授权码"
            return
        }

        // Exchange the code for tokens
        Task {
            do {
                let token = try await exchangeCodeForToken(code: code)
                await MainActor.run {
                    self.currentToken = token
                    self.saveToken(token)
                    self.isAuthenticated = true
                }
                await self.loadAthlete()
            } catch {
                await MainActor.run {
                    self.error = "Token 交换失败: \(error.localizedDescription)"
                }
            }
        }
    }

    private func exchangeCodeForToken(code: String) async throws -> StravaOAuthToken {
        let redirectUri = "strava-sync://oauth-callback/callback"

        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "code": code,
            "grant_type": "authorization_code",
            "redirect_uri": redirectUri
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw StravaOAuthError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw StravaOAuthError.tokenExchangeFailed(errorMessage)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        // Parse the response
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let accessToken = json["access_token"] as? String ?? ""
            let refreshToken = json["refresh_token"] as? String ?? ""
            let expiresIn = json["expires_in"] as? Int ?? 21600
            let expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
            let athleteId = (json["athlete"] as? [String: Any])?["id"] as? Int ?? 0
            let tokenType = json["token_type"] as? String ?? "Bearer"
            let scope = json["scope"] as? String ?? ""

            return StravaOAuthToken(
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresAt: expiresAt,
                expiresIn: expiresIn,
                athleteId: athleteId,
                tokenType: tokenType,
                scope: scope
            )
        }

        throw StravaOAuthError.invalidResponse
    }

    private func refreshToken() async throws {
        guard let token = currentToken else {
            throw StravaOAuthError.notAuthenticated
        }

        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "grant_type": "refresh_token",
            "refresh_token": token.refreshToken
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StravaOAuthError.tokenRefreshFailed
        }

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let accessToken = json["access_token"] as? String ?? ""
            let refreshToken = json["refresh_token"] as? String ?? ""
            let expiresIn = json["expires_in"] as? Int ?? 21600
            let expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
            let athleteId = (json["athlete"] as? [String: Any])?["id"] as? Int ?? 0
            let tokenType = json["token_type"] as? String ?? "Bearer"
            let scope = json["scope"] as? String ?? ""

            let newToken = StravaOAuthToken(
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresAt: expiresAt,
                expiresIn: expiresIn,
                athleteId: athleteId,
                tokenType: tokenType,
                scope: scope
            )

            await MainActor.run {
                self.currentToken = newToken
                self.saveToken(newToken)
            }
        }
    }

    private func fetchAthlete(accessToken: String) async throws -> Athlete {
        var request = URLRequest(url: apiBaseUrl.appendingPathComponent("athlete"))
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StravaOAuthError.fetchAthleteFailed
        }

        let decoder = JSONDecoder()
        return try decoder.decode(Athlete.self, from: data)
    }

    // MARK: - Token Persistence

    private func saveToken(_ token: StravaOAuthToken) {
        if let data = try? JSONEncoder().encode(token) {
            UserDefaults.standard.set(data, forKey: userDefaultsTokenKey)
        }
    }

    private func loadToken() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsTokenKey),
           let token = try? JSONDecoder().decode(StravaOAuthToken.self, from: data) {
            currentToken = token
            isAuthenticated = !token.isExpired
        }
        isInitialLoading = false
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension StravaOAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}

// MARK: - Errors

enum StravaOAuthError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case tokenExchangeFailed(String)
    case tokenRefreshFailed
    case fetchAthleteFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "未登录Strava"
        case .invalidResponse:
            return "无效的服务器响应"
        case .tokenExchangeFailed(let message):
            return "Token交换失败: \(message)"
        case .tokenRefreshFailed:
            return "Token刷新失败，请重新登录"
        case .fetchAthleteFailed:
            return "获取用户信息失败"
        }
    }
}