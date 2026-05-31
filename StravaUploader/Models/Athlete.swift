import Foundation

struct Athlete: Codable {
    let id: Int
    let firstname: String?
    let lastname: String?
    let profile: String?
    let city: String?
    let country: String?

    var displayName: String {
        if let first = firstname, let last = lastname {
            return "\(first) \(last)"
        }
        return firstname ?? lastname ?? "Strava 用户"
    }

    var profilePictureUrl: String? {
        profile
    }
}