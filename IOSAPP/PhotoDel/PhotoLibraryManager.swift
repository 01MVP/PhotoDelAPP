import Foundation
import Photos
import PhotosUI
import SwiftUI

class PhotoLibraryManager: NSObject, ObservableObject {
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var allPhotos: [PHAsset] = []
    @Published var videos: [PHAsset] = []
    @Published var screenshots: [PHAsset] = []
    @Published var favorites: [PHAsset] = []
    @Published var isLoading = false
    @Published var loadingProgress: Double = 0
    
    private var allPhotosResult: PHFetchResult<PHAsset>?
    private let imageManager = PHImageManager.default()
    
    override init() {
        super.init()
        // 延迟初始化，避免启动时崩溃
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.checkAuthorizationStatus()
            PHPhotoLibrary.shared().register(self)
        }
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    func requestAuthorization() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                if status == .authorized {
                    self?.loadPhotos()
                }
            }
        }
    }
    
    // MARK: - Load Photos
    
    func loadPhotos() {
        guard authorizationStatus == .authorized else { return }
        
        isLoading = true
        loadingProgress = 0
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // 获取所有照片
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let allPhotosResult = PHAsset.fetchAssets(with: fetchOptions)
            self?.allPhotosResult = allPhotosResult
            
            // 转换为数组
            var allPhotosArray: [PHAsset] = []
            allPhotosResult.enumerateObjects { asset, _, _ in
                allPhotosArray.append(asset)
            }
            
            DispatchQueue.main.async {
                self?.loadingProgress = 0.3
            }
            
            // 分类照片
            let videos = allPhotosArray.filter { $0.mediaType == .video }
            
            DispatchQueue.main.async {
                self?.loadingProgress = 0.5
            }
            
            // 检测截图 (通过元数据和尺寸判断)
            let screenshots = allPhotosArray.filter { asset in
                asset.mediaType == .image && self?.isScreenshot(asset) == true
            }
            
            DispatchQueue.main.async {
                self?.loadingProgress = 0.7
            }
            
            // 获取收藏的照片
            let favoriteOptions = PHFetchOptions()
            favoriteOptions.predicate = NSPredicate(format: "isFavorite == YES")
            favoriteOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let favoritesResult = PHAsset.fetchAssets(with: favoriteOptions)
            
            var favoritesArray: [PHAsset] = []
            favoritesResult.enumerateObjects { asset, _, _ in
                favoritesArray.append(asset)
            }
            
            DispatchQueue.main.async {
                self?.allPhotos = allPhotosArray
                self?.videos = videos
                self?.screenshots = screenshots
                self?.favorites = favoritesArray
                self?.loadingProgress = 1.0
                self?.isLoading = false
            }
        }
    }
    
    // MARK: - Photo Classification
    
    private func isScreenshot(_ asset: PHAsset) -> Bool {
        // 检查截图的特征
        if #available(iOS 9.0, *) {
            // 通过资源子类型判断
            if asset.mediaSubtypes.contains(.photoScreenshot) {
                return true
            }
        }
        
        // 备用方法：通过设备尺寸判断
        let screenScale = UIScreen.main.scale
        let screenSize = UIScreen.main.bounds.size
        let screenPixelSize = CGSize(
            width: screenSize.width * screenScale,
            height: screenSize.height * screenScale
        )
        
        let assetSize = CGSize(width: CGFloat(asset.pixelWidth), height: CGFloat(asset.pixelHeight))
        
        // 如果尺寸匹配屏幕尺寸，可能是截图
        return abs(assetSize.width - screenPixelSize.width) < 10 &&
               abs(assetSize.height - screenPixelSize.height) < 10
    }
    
    // MARK: - Photo Operations
    
    func deletePhotos(_ assets: [PHAsset], completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    func toggleFavorite(_ asset: PHAsset, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest(for: asset)
            request.isFavorite = !asset.isFavorite
        }) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    func addToFavorites(_ assets: [PHAsset], completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            for asset in assets {
                let request = PHAssetChangeRequest(for: asset)
                request.isFavorite = true
            }
        }) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    // MARK: - Image Loading
    
    func loadImage(for asset: PHAsset, size: CGSize, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        
        imageManager.requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    func loadThumbnail(for asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        loadImage(for: asset, size: CGSize(width: 150, height: 150), completion: completion)
    }
    
    func loadFullImage(for asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        imageManager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    // MARK: - Albums
    
    func createAlbum(title: String, completion: @escaping (PHAssetCollection?, Error?) -> Void) {
        var albumPlaceholder: PHObjectPlaceholder?
        
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
            albumPlaceholder = request.placeholderForCreatedAssetCollection
        }) { success, error in
            DispatchQueue.main.async {
                if success, let placeholder = albumPlaceholder {
                    let album = PHAssetCollection.fetchAssetCollections(
                        withLocalIdentifiers: [placeholder.localIdentifier],
                        options: nil
                    ).firstObject
                    completion(album, nil)
                } else {
                    completion(nil, error)
                }
            }
        }
    }
    
    func addPhotosToAlbum(_ assets: [PHAsset], album: PHAssetCollection, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            if let addAssetRequest = PHAssetCollectionChangeRequest(for: album) {
                addAssetRequest.addAssets(assets as NSArray)
            }
        }) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    // MARK: - Statistics
    
    var totalPhotosCount: Int { allPhotos.count }
    var videosCount: Int { videos.count }
    var screenshotsCount: Int { screenshots.count }
    var favoritesCount: Int { favorites.count }
    
    func getTotalSizeOfPhotos(_ assets: [PHAsset]) -> Int64 {
        // 这是一个估算，实际大小需要异步获取
        return Int64(assets.count) * 3_000_000 // 平均3MB每张照片
    }
}

// MARK: - PHPhotoLibraryChangeObserver

extension PhotoLibraryManager: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async { [weak self] in
            // 检查照片库变化并更新数据
            if let fetchResult = self?.allPhotosResult,
               let changes = changeInstance.changeDetails(for: fetchResult) {
                self?.allPhotosResult = changes.fetchResultAfterChanges
                self?.loadPhotos()
            }
        }
    }
} 