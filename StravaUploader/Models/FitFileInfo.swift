import Foundation

struct FitFileInfo {
    let deviceName: String
    let deviceModel: String
    let recordedDate: Date
    let recordTime: String

    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: recordedDate)
    }

    var displayTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: recordedDate)
    }
}

enum FitFileParser {
    // MAGENE_C606V2_2025-11-30_180626_421800.fit
    static func parse(fileName: String) -> FitFileInfo? {
        let name = (fileName as NSString).deletingPathExtension

        let components = name.split(separator: "_")
        guard components.count >= 4 else { return nil }

        let devicePart = String(components[0])
        let modelPart = String(components[1])
        let datePart = String(components[2])
        let timePart = String(components[3])

        // Parse date (yyyy-MM-dd)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: datePart) else { return nil }

        // Parse time (HHMMSS) and format to HH:mm
        var formattedTime = timePart
        if timePart.count == 6 {
            let hour = String(timePart.prefix(2))
            let minute = String(timePart.dropFirst(2).prefix(2))
            formattedTime = "\(hour):\(minute)"
        }

        return FitFileInfo(
            deviceName: devicePart,
            deviceModel: modelPart,
            recordedDate: date,
            recordTime: formattedTime
        )
    }
}