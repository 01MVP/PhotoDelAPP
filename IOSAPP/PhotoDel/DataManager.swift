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
    @Published var organizeStats = OrganizeStats()
    @Published var currentRealPhotoIndex = 0
    
    // 真实照片管理器
    @Published var photoLibraryManager = PhotoLibraryManager()
    @Published var authorizationRequested = false
    
    // 删除候选库 - 用于批量删除
    @Published var deleteCandidates: Set<PHAsset> = []
    @Published var favoriteCandidates: Set<PHAsset> = []
    
    // 时间组和相册信息缓存
    @Published var timeGroups: [TimeGroupInfo] = []
    @Published var systemAlbums: [AlbumInfo] = []
    @Published var userAlbums: [AlbumInfo] = []
    
    init() {
        setupPhotoLibraryManager()
    }
    
    private func setupPhotoLibraryManager() {
        // 应用启动时立即检查并请求权限
        DispatchQueue.main.async { [weak self] in
            self?.photoLibraryManager.checkAuthorizationStatus()
            if self?.photoLibraryManager.authorizationStatus == .authorized {
                self?.photoLibraryManager.loadPhotos()
                self?.loadTimeGroups()
                self?.loadAlbums()
            } else {
                // 如果未授权，立即请求授权
                self?.requestPhotoLibraryAccess()
            }
        }
    }
    
    // MARK: - 照片权限管理
    func requestPhotoLibraryAccess() {
        authorizationRequested = true
        photoLibraryManager.requestAuthorization()
        
        // 权限获得后重新加载数据
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            if self?.photoLibraryManager.authorizationStatus == .authorized {
                self?.loadTimeGroups()
                self?.loadAlbums()
            }
        }
    }
    
    // MARK: - 真实照片操作
    func getCurrentRealPhoto() -> PHAsset? {
        guard currentRealPhotoIndex < photoLibraryManager.allPhotos.count else { return nil }
        return photoLibraryManager.allPhotos[currentRealPhotoIndex]
    }
    
    func moveToNextRealPhoto() {
        if currentRealPhotoIndex < photoLibraryManager.allPhotos.count - 1 {
            currentRealPhotoIndex += 1
        }
    }
    
    func moveToPreviousRealPhoto() {
        if currentRealPhotoIndex > 0 {
            currentRealPhotoIndex -= 1
        }
    }
    
    // MARK: - 候选库操作（新的删除逻辑）
    func addToDeleteCandidates(_ asset: PHAsset) {
        deleteCandidates.insert(asset)
        updateStats()
        objectWillChange.send()
    }
    
    func removeFromDeleteCandidates(_ asset: PHAsset) {
        deleteCandidates.remove(asset)
        updateStats()
        objectWillChange.send()
    }
    
    func addToFavoriteCandidates(_ asset: PHAsset) {
        favoriteCandidates.insert(asset)
        updateStats()
        objectWillChange.send()
    }
    
    func isInDeleteCandidates(_ asset: PHAsset) -> Bool {
        return deleteCandidates.contains(asset)
    }
    
    func isInFavoriteCandidates(_ asset: PHAsset) -> Bool {
        return favoriteCandidates.contains(asset)
    }
    
    // MARK: - 滑动操作（候选库模式）
    func handleLeftSwipe() {
        guard let currentPhoto = getCurrentRealPhoto() else { return }
        
        if isInDeleteCandidates(currentPhoto) {
            removeFromDeleteCandidates(currentPhoto)
        } else {
            addToDeleteCandidates(currentPhoto)
        }
        moveToNextRealPhoto()
    }
    
    func handleRightSwipe() {
        // 右滑：跳过当前照片，不做任何操作
        moveToNextRealPhoto()
    }
    
    func handleUpSwipe() {
        guard let currentPhoto = getCurrentRealPhoto() else { return }
        addToFavoriteCandidates(currentPhoto)
        moveToNextRealPhoto()
    }
    
    func handleDownSwipe() {
        // 下滑：跳过当前照片
        moveToNextRealPhoto()
    }
    
    func undoLastAction() {
        // 撤销：回到上一张照片
        moveToPreviousRealPhoto()
        objectWillChange.send()
    }
    
    // MARK: - 批量操作（离开页面时执行）
    func executeBatchOperations(completion: @escaping (Bool, Error?) -> Void) {
        let group = DispatchGroup()
        var hasError = false
        var lastError: Error?
        
        // 批量删除
        if !deleteCandidates.isEmpty {
            group.enter()
            photoLibraryManager.deletePhotos(Array(deleteCandidates)) { success, error in
                if !success {
                    hasError = true
                    lastError = error
                }
                group.leave()
            }
        }
        
        // 批量收藏
        if !favoriteCandidates.isEmpty {
            group.enter()
            photoLibraryManager.addToFavorites(Array(favoriteCandidates)) { success, error in
                if !success {
                    hasError = true
                    lastError = error
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if !hasError {
                // 操作成功，清空候选库
                self.deleteCandidates.removeAll()
                self.favoriteCandidates.removeAll()
                self.updateStats()
            }
            completion(!hasError, lastError)
        }
    }
    
    func cancelAllOperations() {
        deleteCandidates.removeAll()
        favoriteCandidates.removeAll()
        updateStats()
        objectWillChange.send()
    }
    
    // MARK: - 统计更新
    private func updateStats() {
        organizeStats.deletedPhotos = deleteCandidates.count
        organizeStats.favoritedPhotos = favoriteCandidates.count
        organizeStats.totalPhotos = photoLibraryManager.totalPhotosCount
        
        // 估算节省的空间（每张照片约3MB）
        organizeStats.spaceSaved = Double(deleteCandidates.count) * 3.0
    }
    
    // MARK: - 筛选功能
    func getRealPhotos(for category: PhotoCategory) -> [PHAsset] {
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
    
    func getOrganizedCount(for category: PhotoCategory) -> Int {
        // 简单示例：假设已删除和已收藏的照片为已整理的照片
        // 实际项目中可能需要从持久化存储中获取
        let deletedCount = deleteCandidates.count
        let favoritedCount = favoriteCandidates.count
        return deletedCount + favoritedCount
    }
    
    // MARK: - 收藏操作
    func toggleFavoriteStatus(_ asset: PHAsset, shouldFavorite: Bool) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest(for: asset)
            request.isFavorite = shouldFavorite
        }) { success, error in
            if let error = error {
                print("Failed to toggle favorite status: \(error)")
            } else {
                print("Successfully \(shouldFavorite ? "favorited" : "unfavorited") photo")
            }
        }
    }
    
    // MARK: - 统一接口
    func getTotalPhotosCount() -> Int {
        return photoLibraryManager.totalPhotosCount
    }
    
    func getVideosCount() -> Int {
        return photoLibraryManager.videosCount
    }
    
    func getScreenshotsCount() -> Int {
        return photoLibraryManager.screenshotsCount
    }
    
    func getFavoritesCount() -> Int {
        return photoLibraryManager.favoritesCount
    }
    
    // MARK: - DeleteConfirmView需要的方法
    func performBatchOperations() {
        executeBatchOperations { success, error in
            if success {
                print("批量操作执行成功")
            } else {
                print("批量操作执行失败: \(error?.localizedDescription ?? "未知错误")")
            }
        }
    }
    
    func clearCandidates() {
        cancelAllOperations()
    }
    
    // MARK: - 时间组数据加载
    func loadTimeGroups() {
        guard photoLibraryManager.authorizationStatus == .authorized else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let calendar = Calendar.current
            let now = Date()
            
            var groups: [TimeGroupInfo] = []
            
            // 今天的照片
            let todayPhotos = self.getPhotosForTimeGroup(.today)
            groups.append(TimeGroupInfo(timeGroup: .today, photosCount: todayPhotos.count, progress: 0.2))
            
            // 本周的照片
            let thisWeekPhotos = self.getPhotosForTimeGroup(.thisWeek)
            groups.append(TimeGroupInfo(timeGroup: .thisWeek, photosCount: thisWeekPhotos.count, progress: 0.1))
            
            // 本月的照片
            let thisMonthPhotos = self.getPhotosForTimeGroup(.thisMonth)
            groups.append(TimeGroupInfo(timeGroup: .thisMonth, photosCount: thisMonthPhotos.count, progress: 0.15))
            
            // 上个月的照片
            let lastMonthPhotos = self.getPhotosForTimeGroup(.lastMonth)
            groups.append(TimeGroupInfo(timeGroup: .lastMonth, photosCount: lastMonthPhotos.count, progress: 0.05))
            
            // 更早的照片
            let olderPhotos = self.getPhotosForTimeGroup(.olderPhotos)
            groups.append(TimeGroupInfo(timeGroup: .olderPhotos, photosCount: olderPhotos.count, progress: 0.0))
            
            DispatchQueue.main.async {
                self.timeGroups = groups
            }
        }
    }
    
    // MARK: - 相册数据加载
    func loadAlbums() {
        guard photoLibraryManager.authorizationStatus == .authorized else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var systemAlbums: [AlbumInfo] = []
            var userAlbums: [AlbumInfo] = []
            
            // 系统相册
            let smartAlbumTypes: [PHAssetCollectionSubtype] = [
                .smartAlbumUserLibrary,  // 全部照片
                .smartAlbumRecentlyAdded, // 最近项目
                .smartAlbumFavorites,    // 收藏
                .smartAlbumScreenshots,  // 截图
                .smartAlbumVideos        // 视频
            ]
            
            for subtype in smartAlbumTypes {
                let collections = PHAssetCollection.fetchAssetCollections(
                    with: .smartAlbum,
                    subtype: subtype,
                    options: nil
                )
                
                collections.enumerateObjects { collection, _, _ in
                    let fetchOptions = PHFetchOptions()
                    let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
                    
                    if assets.count > 0 {
                        let albumType = self.getAlbumType(for: subtype)
                        let thumbnailAsset = assets.firstObject
                        let albumInfo = AlbumInfo(
                            assetCollection: collection,
                            type: albumType,
                            photosCount: assets.count,
                            thumbnailAsset: thumbnailAsset
                        )
                        systemAlbums.append(albumInfo)
                    }
                }
            }
            
            // 用户创建的相册
            let userCollections = PHAssetCollection.fetchAssetCollections(
                with: .album,
                subtype: .any,
                options: nil
            )
            
            userCollections.enumerateObjects { collection, _, _ in
                let fetchOptions = PHFetchOptions()
                let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
                
                let thumbnailAsset = assets.firstObject
                let albumInfo = AlbumInfo(
                    assetCollection: collection,
                    type: .userCreated,
                    photosCount: assets.count,
                    thumbnailAsset: thumbnailAsset
                )
                userAlbums.append(albumInfo)
            }
            
            DispatchQueue.main.async {
                self.systemAlbums = systemAlbums
                self.userAlbums = userAlbums
            }
        }
    }
    
    // MARK: - 时间筛选方法
    func getPhotosForTimeGroup(_ timeGroup: TimeGroup) -> [PHAsset] {
        let calendar = Calendar.current
        let now = Date()
        
        return photoLibraryManager.allPhotos.filter { asset in
            guard let creationDate = asset.creationDate else { return false }
            
            switch timeGroup {
            case .today:
                return calendar.isDateInToday(creationDate)
            case .thisWeek:
                return calendar.isDate(creationDate, equalTo: now, toGranularity: .weekOfYear) && !calendar.isDateInToday(creationDate)
            case .thisMonth:
                return calendar.isDate(creationDate, equalTo: now, toGranularity: .month) && !calendar.isDate(creationDate, equalTo: now, toGranularity: .weekOfYear)
            case .lastMonth:
                let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
                return calendar.isDate(creationDate, equalTo: lastMonth, toGranularity: .month)
            case .olderPhotos:
                let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: now) ?? now
                return creationDate < twoMonthsAgo
            }
        }
    }
    
    // MARK: - 相册筛选方法
    func getPhotosForAlbum(_ albumInfo: AlbumInfo) -> [PHAsset] {
        guard let assetCollection = albumInfo.assetCollection else {
            // 如果没有 assetCollection，根据类型返回对应的照片
            switch albumInfo.type {
            case .all:
                return photoLibraryManager.allPhotos
            case .favorites:
                return photoLibraryManager.favorites
            case .screenshots:
                return photoLibraryManager.screenshots
            case .videos:
                return photoLibraryManager.videos
            default:
                return []
            }
        }
        
        let fetchOptions = PHFetchOptions()
        let assets = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
        
        var result: [PHAsset] = []
        assets.enumerateObjects { asset, _, _ in
            result.append(asset)
        }
        
        return result
    }
    
    // MARK: - 辅助方法
    private func getAlbumType(for subtype: PHAssetCollectionSubtype) -> AlbumType {
        switch subtype {
        case .smartAlbumUserLibrary:
            return .all
        case .smartAlbumRecentlyAdded:
            return .recents
        case .smartAlbumFavorites:
            return .favorites
        case .smartAlbumScreenshots:
            return .screenshots
        case .smartAlbumVideos:
            return .videos
        default:
            return .userCreated
        }
    }
    
    // MARK: - 相册操作
    func getAllAlbums() -> [AlbumInfo] {
        return systemAlbums + userAlbums
    }
    
    func getSystemAlbums() -> [AlbumInfo] {
        return systemAlbums
    }
    
    func getUserAlbums() -> [AlbumInfo] {
        return userAlbums
    }
} 