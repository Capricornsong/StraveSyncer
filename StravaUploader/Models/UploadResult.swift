import Foundation

enum UploadResult {
    case success(activityId: Int, activityUrl: String)
    case duplicate(activityId: Int, activityUrl: String)
    case failure(error: String)
}