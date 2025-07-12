//
//  DataManager.swift
//  PhotoDel
//
//  Created by PhotoDel Team on 11/7/25.
//

import Foundation
import SwiftUI
import Photos

class DataManager: ObservableObject {
    @Published var photos: [Photo] = []
    @Published var albums: [Album] = []
    @Published var organizeStats = OrganizeStats()
    @Published var currentSwipeIndex = 0
    
    // 真实照片管理器
    @Published var photoLibraryManager = PhotoLibraryManager()
    @Published var useRealPhotos = false
    @Published var authorizationRequested = false
    @Published var currentRealPhotoIndex = 0
    
    // 虚拟照片名称（使用系统图标代替真实图片）
    private let samplePhotoNames = [
        "photo1", "photo2", "photo3", "photo4", "photo5",
        "photo6", "photo7", "photo8", "photo9", "photo10",
        "photo11", "photo12", "photo13", "photo14", "photo15",
        "photo16", "photo17", "photo18", "photo19", "photo20"
    ]
    
    private let sampleLocations = [
        "北京", "上海", "深圳", "广州", "杭州", "成都", "西安", "武汉", "南京", "苏州",
        nil, nil, nil // 一些照片没有位置信息
    ]
    
    init() {
        generateSampleData()
        setupPhotoLibraryManager()
    }
    
    private func setupPhotoLibraryManager() {
        // 延迟设置，避免启动时立即调用Photos API
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            // 监听授权状态变化
            if self?.photoLibraryManager.authorizationStatus == .authorized {
                self?.useRealPhotos = true
                self?.photoLibraryManager.loadPhotos()
            }
        }
    }
    
    // MARK: - 生成示例数据
    private func generateSampleData() {
        generateSamplePhotos()
        generateSampleAlbums()
        updateStats()
    }
    
    private func generateSamplePhotos() {
        let calendar = Calendar.current
        let now = Date()
        
        // 生成1234张示例照片
        for i in 0..<1234 {
            let imageName = samplePhotoNames.randomElement() ?? "photo1"
            
            // 生成不同时间的照片
            let daysAgo = Int.random(in: 0...365)
            let hoursAgo = Int.random(in: 0...23)
            let minutesAgo = Int.random(in: 0...59)
            
            let photoDate = calendar.date(byAdding: .day, value: -daysAgo, to: now) ??
                           calendar.date(byAdding: .hour, value: -hoursAgo, to: now) ??
                           calendar.date(byAdding: .minute, value: -minutesAgo, to: now) ?? now
            
            let location = sampleLocations.randomElement() ?? nil
            let isVideo = Double.random(in: 0...1) < 0.1 // 10%的视频
            let isScreenshot = Double.random(in: 0...1) < 0.15 // 15%的截图
            let isFavorited = Double.random(in: 0...1) < 0.08 // 8%的收藏
            
            var category: PhotoCategory = .all
            var status: PhotoStatus = .unprocessed
            
            if isVideo {
                category = .videos
            } else if isScreenshot {
                category = .screenshots
            } else if isFavorited {
                category = .favorites
                status = .favorited
            }
            
            // 一些照片已经被处理过
            if Double.random(in: 0...1) < 0.3 {
                status = [.kept, .toDelete, .skipped].randomElement() ?? .unprocessed
            }
            
            let photo = Photo(
                imageName: imageName,
                dateCreated: photoDate,
                location: location,
                device: ["iPhone 15 Pro", "iPhone 14 Pro", "iPhone 13 Pro"].randomElement() ?? "iPhone 15 Pro",
                status: status,
                category: category,
                isVideo: isVideo,
                fileSize: Double.random(in: 1.5...8.0)
            )
            
            photos.append(photo)
        }
        
        // 按时间排序
        photos.sort { $0.dateCreated > $1.dateCreated }
    }
    
    private func generateSampleAlbums() {
        let albumsData = [
            ("收藏", "heart.fill", Color.red),
            ("朋友", "person.2.fill", Color.green),
            ("旅行", "airplane", Color.purple),
            ("工作", "briefcase.fill", Color.blue),
            ("家庭", "house.fill", Color.orange),
            ("美食", "fork.knife", Color.yellow),
            ("风景", "mountain.2.fill", Color.teal),
            ("其他", "folder.fill", Color.gray)
        ]
        
        for (name, icon, color) in albumsData {
            let albumPhotos = photos.filter { photo in
                // 随机分配一些照片到相册
                Double.random(in: 0...1) < 0.1
            }
            
            let album = Album(name: name, icon: icon, color: color, photos: Array(albumPhotos.prefix(50)))
            albums.append(album)
        }
    }
    
    // MARK: - 统计相关
    private func updateStats() {
        organizeStats.totalPhotos = photos.count
        organizeStats.deletedPhotos = photos.filter { $0.status == .toDelete }.count
        organizeStats.keptPhotos = photos.filter { $0.status == .kept }.count
        organizeStats.favoritedPhotos = photos.filter { $0.status == .favorited }.count
        
        let deletedPhotos = photos.filter { $0.status == .toDelete }
        organizeStats.spaceSaved = deletedPhotos.reduce(0) { $0 + $1.fileSize }
    }
    
    // MARK: - 照片操作
    func getCurrentPhoto() -> Photo? {
        guard currentSwipeIndex < photos.count else { return nil }
        return photos[currentSwipeIndex]
    }
    
    func moveToNextPhoto() {
        if currentSwipeIndex < photos.count - 1 {
            currentSwipeIndex += 1
        }
    }
    
    func deleteCurrentPhoto() {
        guard currentSwipeIndex < photos.count else { return }
        photos[currentSwipeIndex].status = .toDelete
        organizeStats.deletedPhotos += 1
        organizeStats.spaceSaved += photos[currentSwipeIndex].fileSize
        moveToNextPhoto()
        objectWillChange.send()
    }
    
    func keepCurrentPhoto() {
        guard currentSwipeIndex < photos.count else { return }
        photos[currentSwipeIndex].status = .kept
        organizeStats.keptPhotos += 1
        moveToNextPhoto()
        objectWillChange.send()
    }
    
    func favoriteCurrentPhoto() {
        guard currentSwipeIndex < photos.count else { return }
        photos[currentSwipeIndex].status = .favorited
        photos[currentSwipeIndex].category = .favorites
        organizeStats.favoritedPhotos += 1
        moveToNextPhoto()
        objectWillChange.send()
    }
    
    func skipCurrentPhoto() {
        guard currentSwipeIndex < photos.count else { return }
        photos[currentSwipeIndex].status = .skipped
        moveToNextPhoto()
        objectWillChange.send()
    }
    
    func undoLastAction() {
        if currentSwipeIndex > 0 {
            currentSwipeIndex -= 1
            photos[currentSwipeIndex].status = .unprocessed
            updateStats()
            objectWillChange.send()
        }
    }
    
    // MARK: - 筛选功能
    func getPhotos(for category: PhotoCategory) -> [Photo] {
        switch category {
        case .all:
            return photos
        case .videos:
            return photos.filter { $0.isVideo }
        case .screenshots:
            return photos.filter { $0.category == .screenshots }
        case .favorites:
            return photos.filter { $0.status == .favorited }
        }
    }
    
    func getPhotos(for timeGroup: TimeGroup) -> [Photo] {
        return photos.filter { $0.timeGroup == timeGroup }
    }
    
    func getPhotoCount(for category: PhotoCategory) -> Int {
        return getPhotos(for: category).count
    }
    
    func getPhotoCount(for timeGroup: TimeGroup) -> Int {
        return getPhotos(for: timeGroup).count
    }
    
    // MARK: - 相册操作
    func addAlbum(name: String, icon: String, color: Color) {
        let album = Album(name: name, icon: icon, color: color)
        albums.append(album)
        objectWillChange.send()
    }
    
    func deleteAlbum(at indexSet: IndexSet) {
        albums.remove(atOffsets: indexSet)
        objectWillChange.send()
    }
    
    func moveAlbum(from source: IndexSet, to destination: Int) {
        albums.move(fromOffsets: source, toOffset: destination)
        objectWillChange.send()
    }
    
    // MARK: - 批量操作
    func confirmDeletion() {
        photos.removeAll { $0.status == .toDelete }
        currentSwipeIndex = 0
        updateStats()
        objectWillChange.send()
    }
    
    func cancelDeletion() {
        for i in photos.indices {
            if photos[i].status == .toDelete {
                photos[i].status = .unprocessed
            }
        }
        updateStats()
        objectWillChange.send()
    }
    
    // MARK: - 真实照片操作
    func requestPhotoLibraryAccess() {
        authorizationRequested = true
        photoLibraryManager.requestAuthorization()
    }
    
    func switchToRealPhotos() {
        if photoLibraryManager.authorizationStatus == .authorized {
            useRealPhotos = true
            photoLibraryManager.loadPhotos()
        } else {
            requestPhotoLibraryAccess()
        }
    }
    
    func switchToVirtualPhotos() {
        useRealPhotos = false
    }
    
    func getCurrentRealPhoto() -> PHAsset? {
        guard useRealPhotos && currentRealPhotoIndex < photoLibraryManager.allPhotos.count else { return nil }
        return photoLibraryManager.allPhotos[currentRealPhotoIndex]
    }
    
    func moveToNextRealPhoto() {
        if currentRealPhotoIndex < photoLibraryManager.allPhotos.count - 1 {
            currentRealPhotoIndex += 1
        }
    }
    
    func deleteCurrentRealPhoto() {
        guard let currentPhoto = getCurrentRealPhoto() else { return }
        
        photoLibraryManager.deletePhotos([currentPhoto]) { [weak self] success, error in
            if success {
                self?.organizeStats.deletedPhotos += 1
                self?.organizeStats.spaceSaved += 3.0 // 估算3MB
                self?.moveToNextRealPhoto()
                self?.objectWillChange.send()
            } else if let error = error {
                print("删除照片失败: \(error.localizedDescription)")
            }
        }
    }
    
    func favoriteCurrentRealPhoto() {
        guard let currentPhoto = getCurrentRealPhoto() else { return }
        
        photoLibraryManager.toggleFavorite(currentPhoto) { [weak self] success, error in
            if success {
                self?.organizeStats.favoritedPhotos += 1
                self?.moveToNextRealPhoto()
                self?.objectWillChange.send()
            } else if let error = error {
                print("收藏照片失败: \(error.localizedDescription)")
            }
        }
    }
    
    func skipCurrentRealPhoto() {
        moveToNextRealPhoto()
        objectWillChange.send()
    }
    
    // MARK: - 统一接口（兼容虚拟和真实照片）
    func getTotalPhotosCount() -> Int {
        return useRealPhotos ? photoLibraryManager.totalPhotosCount : photos.count
    }
    
    func getVideosCount() -> Int {
        return useRealPhotos ? photoLibraryManager.videosCount : photos.filter { $0.isVideo }.count
    }
    
    func getScreenshotsCount() -> Int {
        return useRealPhotos ? photoLibraryManager.screenshotsCount : photos.filter { $0.category == .screenshots }.count
    }
    
    func getFavoritesCount() -> Int {
        return useRealPhotos ? photoLibraryManager.favoritesCount : photos.filter { $0.status == .favorited }.count
    }
    
    func getRealPhotos(for category: PhotoCategory) -> [PHAsset] {
        guard useRealPhotos else { return [] }
        
        switch category {
        case .all:
            return photoLibraryManager.allPhotos
        case .videos:
            return photoLibraryManager.videos
        case .screenshots:
            return photoLibraryManager.screenshots
        case .favorites:
            return photoLibraryManager.favorites
        }
    }
} 