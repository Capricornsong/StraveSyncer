import Foundation

struct StravaUploadResponse: Codable {
    let id: Int64?
    let idStr: String?
    let externalId: String?
    let name: String?
    let workflow: String?
    let progress: Int?
    let error: String?
    let status: String?
    let activityId: Int64?

    enum CodingKeys: String, CodingKey {
        case id
        case idStr = "id_str"
        case externalId = "external_id"
        case name, workflow, progress, error, status
        case activityId = "activity_id"
    }

    var isSuccess: Bool {
        workflow == "new_activity" || activityId != nil
    }

    var isProcessing: Bool {
        status != nil && activityId == nil && error == nil
    }

    var isDuplicate: Bool {
        if let error = error {
            return error.lowercased().contains("duplicate")
        }
        return false
    }

    var duplicateActivityId: Int64? {
        guard isDuplicate else { return nil }
        if let error = error,
           let range = error.range(of: "/activities/"),
           let endRange = error.range(of: "'", range: range.upperBound..<error.endIndex) {
            let idString = String(error[range.upperBound..<endRange.lowerBound])
            return Int64(idString)
        }
        return nil
    }
}

class StravaUploadService {
    private let apiBaseUrl = URL(string: "https://www.strava.com/api/v3")!
    private let uploadUrl = URL(string: "https://www.strava.com/api/v3/uploads")!

    private let oauthService: StravaOAuthService

    init(oauthService: StravaOAuthService) {
        self.oauthService = oauthService
    }

    func uploadFitFile(
        fileData: Data,
        fileName: String,
        activityType: String,
        name: String?,
        description: String?,
        isPrivate: Bool,
        statusUpdate: ((String) -> Void)? = nil
    ) async throws -> UploadResult {
        let accessToken = try await oauthService.getValidAccessToken()
        print("[DEBUG] Using access token: \(accessToken.prefix(20))...")

        // Step 1: Upload the file
        let uploadResponse = try await uploadFile(
            accessToken: accessToken,
            fileData: fileData,
            fileName: fileName,
            activityType: activityType,
            name: name,
            description: description,
            isPrivate: isPrivate
        )

        guard let uploadId = uploadResponse.id else {
            return .failure(error: "上传失败：未获得上传 ID")
        }

        print("[DEBUG] Upload initiated, uploadId: \(uploadId), status: \(uploadResponse.status ?? "nil")")

        // Step 2: Poll for upload status
        return try await pollUploadStatus(uploadId: uploadId, accessToken: accessToken, statusUpdate: statusUpdate)
    }

    private func uploadFile(
        accessToken: String,
        fileData: Data,
        fileName: String,
        activityType: String,
        name: String?,
        description: String?,
        isPrivate: Bool
    ) async throws -> StravaUploadResponse {
        let boundary = UUID().uuidString
        var request = URLRequest(url: uploadUrl)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"activity_type\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(activityType)\r\n".data(using: .utf8)!)

        if let name = name, !name.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"name\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(name)\r\n".data(using: .utf8)!)
        }

        if let description = description, !description.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"description\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(description)\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"private\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(isPrivate ? 1 : 0)\r\n".data(using: .utf8)!)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"external_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("fit_\(UUID().uuidString)\r\n".data(using: .utf8)!)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"data_type\"\r\n\r\n".data(using: .utf8)!)
        body.append("fit\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        print("[DEBUG] Sending upload request to: \(uploadUrl)")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "StravaUploadService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的服务器响应"])
        }

        print("[DEBUG] Upload response status code: \(httpResponse.statusCode)")

        if httpResponse.statusCode == 401 {
            throw StravaOAuthError.notAuthenticated
        }

        guard httpResponse.statusCode == 201 || httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw NSError(domain: "StravaUploadService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        // Try to decode as array first (for error responses like duplicates)
        if let responseArray = try? JSONDecoder().decode([StravaUploadResponse].self, from: data),
           let firstResponse = responseArray.first {
            print("[DEBUG] Upload response (array): \(String(data: data, encoding: .utf8) ?? "nil")")
            return firstResponse
        }

        // Fall back to single object
        let uploadResponse = try JSONDecoder().decode(StravaUploadResponse.self, from: data)
        print("[DEBUG] Upload response: \(String(data: data, encoding: .utf8) ?? "nil")")
        return uploadResponse
    }

    private func pollUploadStatus(
        uploadId: Int64,
        accessToken: String,
        statusUpdate: ((String) -> Void)?
    ) async throws -> UploadResult {
        let statusUrl = apiBaseUrl.appendingPathComponent("uploads/\(uploadId)")
        var pollCount = 0
        let maxPolls = 60

        while pollCount < maxPolls {
            pollCount += 1
            print("[DEBUG] Polling status, attempt \(pollCount)/\(maxPolls)")

            statusUpdate?("正在处理... (\(pollCount)s)")

            var request = URLRequest(url: statusUrl)
            request.httpMethod = "GET"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                continue
            }

            let uploadResponse = try JSONDecoder().decode(StravaUploadResponse.self, from: data)
            print("[DEBUG] Poll response: id=\(uploadResponse.id ?? 0), activity_id=\(uploadResponse.activityId ?? 0), error=\(uploadResponse.error ?? "nil"), status=\(uploadResponse.status ?? "nil")")

            if let activityId = uploadResponse.activityId {
                let activityUrl = "https://www.strava.com/activities/\(activityId)"
                print("[DEBUG] Upload complete! Activity ID: \(activityId)")
                statusUpdate?("处理完成!")
                return .success(activityId: Int(activityId), activityUrl: activityUrl)
            }

            if uploadResponse.isDuplicate {
                if let duplicateId = uploadResponse.duplicateActivityId {
                    let activityUrl = "https://www.strava.com/activities/\(duplicateId)"
                    print("[DEBUG] Duplicate detected! Existing activity ID: \(duplicateId)")
                    statusUpdate?("检测到重复文件")
                    return .duplicate(activityId: Int(duplicateId), activityUrl: activityUrl)
                }
                statusUpdate?("文件已上传")
                return .failure(error: "该文件已上传过")
            }

            if let error = uploadResponse.error {
                statusUpdate?("处理失败")
                return .failure(error: error)
            }

            if let status = uploadResponse.status?.lowercased(),
               (status.contains("error") || status.contains("fail")) {
                statusUpdate?("处理失败")
                return .failure(error: uploadResponse.error ?? uploadResponse.status ?? "上传失败")
            }

            try await Task.sleep(nanoseconds: 1_000_000_000)
        }

        statusUpdate?("处理超时")
        return .failure(error: "上传处理超时，请稍后在 Strava 查看")
    }
}