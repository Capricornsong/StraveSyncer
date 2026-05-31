import Foundation

enum ActivityType: String, CaseIterable, Identifiable {
    case ride = "Ride"
    case virtualRide = "VirtualRide"
    case gravelRide = "GravelRide"
    case ebikeRide = "EBikeRide"
    case run = "Run"
    case virtualRun = "VirtualRun"
    case swim = "Swim"
    case walk = "Walk"
    case hike = "Hike"
    case alpineSki = "AlpineSki"
    case backcountrySki = "BackcountrySki"
    case nordicSki = "NordicSki"
    case rollerSki = "RollerSki"
    case snowboard = "Snowboard"
    case snowshoe = "Snowshoe"
    case kayaking = "Kayaking"
    case rowing = "Rowing"
    case standUpPaddling = "StandUpPaddling"
    case surfing = "Surfing"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ride: return "骑行 (Ride)"
        case .virtualRide: return "虚拟骑行 (Virtual Ride)"
        case .gravelRide: return "砂石骑行 (Gravel Ride)"
        case .ebikeRide: return "电助力骑行 (E-Bike)"
        case .run: return "跑步 (Run)"
        case .virtualRun: return "虚拟跑步 (Virtual Run)"
        case .swim: return "游泳 (Swim)"
        case .walk: return "步行 (Walk)"
        case .hike: return "徒步 (Hike)"
        case .alpineSki: return "高山滑雪 (Alpine Ski)"
        case .backcountrySki: return "越野滑雪 (Backcountry Ski)"
        case .nordicSki: return "北欧式滑雪 (Nordic Ski)"
        case .rollerSki: return "滚轴滑雪 (Roller Ski)"
        case .snowboard: return "单板滑雪 (Snowboard)"
        case .snowshoe: return "雪地健行 (Snowshoe)"
        case .kayaking: return "皮划艇 (Kayaking)"
        case .rowing: return "划船 (Rowing)"
        case .standUpPaddling: return "站立划水 (SUP)"
        case .surfing: return "冲浪 (Surfing)"
        }
    }

    var icon: String {
        switch self {
        case .ride, .virtualRide, .gravelRide, .ebikeRide:
            return "figure.outdoor.cycle"
        case .run, .virtualRun:
            return "figure.run"
        case .swim:
            return "figure.pool.swim"
        case .walk, .hike:
            return "figure.walk"
        case .alpineSki, .backcountrySki, .nordicSki, .rollerSki, .snowboard:
            return "figure.skiing"
        case .snowshoe:
            return "figure.hiking"
        case .kayaking, .rowing, .standUpPaddling:
            return "figure.kayaking"
        case .surfing:
            return "figure.surfing"
        }
    }
}