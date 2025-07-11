//
//  Models.swift
//  PhotoDel
//
//  Created by PhotoDel Team on 11/7/25.
//

import Foundation
import SwiftUI

// MARK: - 照片状态
enum PhotoStatus: String, CaseIterable {
    case unprocessed = "未处理"
    case kept = "已保留"
    case toDelete = "待删除"
    case favorited = "已收藏"
    case skipped = "已跳过"
}

// MARK: - 照片分类
enum PhotoCategory: String, CaseIterable {
    case all = "全部照片"
    case videos = "视频"
    case screenshots = "截图"
    case favorites = "收藏"
    
    var icon: String {
        switch self {
        case .all: return "photo.on.rectangle"
        case .videos: return "video"
        case .screenshots: return "iphone"
        case .favorites: return "heart.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .blue
        case .videos: return .purple
        case .screenshots: return .green
        case .favorites: return .yellow
        }
    }
}

// MARK: - 时间分组
enum TimeGroup: String, CaseIterable {
    case today = "今天的照片"
    case thisWeek = "本周的照片"
    case january2025 = "2025年1月"
    case december2024 = "2024年12月"
    case november2024 = "2024年11月"
    
    var icon: String {
        switch self {
        case .today: return "clock"
        case .thisWeek: return "calendar"
        case .january2025, .december2024, .november2024: return "calendar"
        }
    }
    
    var color: Color {
        switch self {
        case .today: return .orange
        case .thisWeek: return .indigo
        case .january2025: return .teal
        case .december2024: return .gray
        case .november2024: return .gray
        }
    }
    
    var progress: Double {
        switch self {
        case .today: return 0.85
        case .thisWeek: return 0.62
        case .january2025: return 0.45
        case .december2024: return 0.78
        case .november2024: return 0.92
        }
    }
    
    var progressColor: Color {
        switch progress {
        case 0.9...: return .yellow
        case 0.8..<0.9: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .teal
        default: return .purple
        }
    }
}

// MARK: - 照片模型
struct Photo: Identifiable {
    let id = UUID()
    let imageName: String
    let dateCreated: Date
    let location: String?
    let device: String
    var status: PhotoStatus
    var category: PhotoCategory
    let isVideo: Bool
    let fileSize: Double // MB
    
    init(imageName: String, 
         dateCreated: Date = Date(), 
         location: String? = nil, 
         device: String = "iPhone 15 Pro",
         status: PhotoStatus = .unprocessed,
         category: PhotoCategory = .all,
         isVideo: Bool = false,
         fileSize: Double = 3.2) {
        self.imageName = imageName
        self.dateCreated = dateCreated
        self.location = location
        self.device = device
        self.status = status
        self.category = category
        self.isVideo = isVideo
        self.fileSize = fileSize
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: dateCreated)
    }
    
    var timeGroup: TimeGroup {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(dateCreated) {
            return .today
        } else if calendar.isDate(dateCreated, equalTo: now, toGranularity: .weekOfYear) {
            return .thisWeek
        } else {
            let components = calendar.dateComponents([.year, .month], from: dateCreated)
            if components.year == 2025 && components.month == 1 {
                return .january2025
            } else if components.year == 2024 && components.month == 12 {
                return .december2024
            } else {
                return .november2024
            }
        }
    }
}

// MARK: - 相册模型
struct Album: Identifiable {
    let id = UUID()
    var name: String
    let icon: String
    let color: Color
    var photos: [Photo]
    let dateCreated: Date
    
    init(name: String, icon: String, color: Color, photos: [Photo] = []) {
        self.name = name
        self.icon = icon
        self.color = color
        self.photos = photos
        self.dateCreated = Date()
    }
    
    var photoCount: Int {
        photos.count
    }
    
    var coverPhoto: Photo? {
        photos.first
    }
}

// MARK: - 整理统计
struct OrganizeStats {
    var totalPhotos: Int = 0
    var deletedPhotos: Int = 0
    var keptPhotos: Int = 0
    var favoritedPhotos: Int = 0
    var spaceSaved: Double = 0.0 // MB
    var timeSpent: TimeInterval = 0.0
    
    var formattedSpaceSaved: String {
        if spaceSaved < 1000 {
            return String(format: "%.0f MB", spaceSaved)
        } else {
            return String(format: "%.1f GB", spaceSaved / 1024)
        }
    }
    
    var formattedTimeSpent: String {
        let minutes = Int(timeSpent) / 60
        let seconds = Int(timeSpent) % 60
        return "\(minutes)分\(seconds)秒"
    }
} 