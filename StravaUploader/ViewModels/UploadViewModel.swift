import SwiftUI
import UniformTypeIdentifiers

@MainActor
class UploadViewModel: ObservableObject {
    @Published var selectedFileURL: URL?
    @Published var selectedFileData: Data?
    @Published var selectedFileName: String = ""
    @Published var fitFileInfo: FitFileInfo?
    @Published var activityName: String = ""
    @Published var activityDescription: String = ""
    @Published var selectedActivityType: ActivityType = .ride
    @Published var isPrivate: Bool = false

    @Published var isUploading: Bool = false
    @Published var uploadResult: UploadResult?
    @Published var uploadStatus: String = ""

    // OAuth state
    @Published var isLoggedIn: Bool = false
    @Published var athlete: Athlete?
    @Published var isLoggingIn: Bool = false
    @Published var loginError: String?

    let oauthService: StravaOAuthService
    private var uploadService: StravaUploadService

    init() {
        self.oauthService = StravaOAuthService()
        self.uploadService = StravaUploadService(oauthService: oauthService)

        // Check if already logged in
        if oauthService.isLoggedIn {
            isLoggedIn = true
            Task {
                await loadAthlete()
            }
        }
    }

    var hasSelectedFile: Bool {
        selectedFileData != nil
    }

    var canUpload: Bool {
        hasSelectedFile && !isUploading && isLoggedIn
    }

    // MARK: - Authentication

    func login() {
        isLoggingIn = true
        loginError = nil

        oauthService.login()

        Task {
            // Wait for auth session to finish (user interaction)
            while oauthService.isLoading {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }

            // If there's an error, stop here
            if let error = oauthService.error {
                await MainActor.run {
                    self.isLoggingIn = false
                    self.loginError = error
                }
                return
            }

            // Wait for token exchange and athlete loading to complete
            while !oauthService.isLoggedIn || oauthService.athlete == nil {
                if oauthService.error != nil { break }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }

            await MainActor.run {
                self.isLoggingIn = false
                self.isLoggedIn = self.oauthService.isLoggedIn
                self.athlete = self.oauthService.athlete
                if let error = self.oauthService.error {
                    self.loginError = error
                }
            }
        }
    }

    func logout() {
        oauthService.logout()
        isLoggedIn = false
        athlete = nil
    }

    func loadAthlete() async {
        await oauthService.loadAthlete()
        await MainActor.run {
            self.athlete = self.oauthService.athlete
            self.isLoggedIn = self.oauthService.isLoggedIn
            self.loginError = self.oauthService.error
        }
    }

    // MARK: - File Selection

    func handleFileSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            guard url.startAccessingSecurityScopedResource() else {
                uploadResult = .failure(error: "无法访问选择的文件")
                return
            }

            defer {
                url.stopAccessingSecurityScopedResource()
            }

            do {
                let data = try Data(contentsOf: url)
                selectedFileData = data
                selectedFileURL = url
                selectedFileName = url.lastPathComponent
                fitFileInfo = FitFileParser.parse(fileName: selectedFileName)
                uploadResult = nil
            } catch {
                uploadResult = .failure(error: "读取文件失败: \(error.localizedDescription)")
            }

        case .failure(let error):
            uploadResult = .failure(error: "选择文件失败: \(error.localizedDescription)")
        }
    }

    // MARK: - Upload

    func upload() async {
        guard let fileData = selectedFileData else { return }

        isUploading = true
        uploadResult = nil
        uploadStatus = "正在上传..."

        uploadService = StravaUploadService(oauthService: oauthService)

        do {
            let result = try await uploadService.uploadFitFile(
                fileData: fileData,
                fileName: selectedFileName,
                activityType: selectedActivityType.rawValue,
                name: activityName.isEmpty ? nil : activityName,
                description: activityDescription.isEmpty ? nil : activityDescription,
                isPrivate: isPrivate,
                statusUpdate: { [weak self] status in
                    Task { @MainActor in
                        self?.uploadStatus = status
                    }
                }
            )
            uploadResult = result
        } catch {
            uploadResult = .failure(error: "上传异常: \(error.localizedDescription)")
        }

        isUploading = false
        uploadStatus = ""
    }

    func reset() {
        selectedFileURL = nil
        selectedFileData = nil
        selectedFileName = ""
        fitFileInfo = nil
        activityName = ""
        activityDescription = ""
        selectedActivityType = .ride
        isPrivate = false
        uploadResult = nil
    }
}