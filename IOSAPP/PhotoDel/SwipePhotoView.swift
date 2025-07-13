//
//  SwipePhotoView.swift
//  PhotoDel
//
//  Created by PhotoDel Team on 11/7/25.
//

import SwiftUI
import Photos

struct SwipePhotoView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    let selectedCategory: PhotoCategory?
    let selectedTimeGroup: String?
    let selectedAlbumInfo: AlbumInfo?
    
    @State private var dragOffset = CGSize.zero
    @State private var rotationAngle: Double = 0
    @State private var showDeleteConfirm = false
    @State private var swipeDirection: SwipeDirection?
    @State private var showPhotoAccessAlert = false
    @State private var showBatchConfirm = false
    
    enum SwipeDirection {
        case left, right, up, down
    }
    
    private var currentRealPhoto: PHAsset? {
        return dataManager.getCurrentRealPhoto()
    }
    
    private var filteredRealPhotos: [PHAsset] {
        if let albumInfo = selectedAlbumInfo {
            return dataManager.getPhotosForAlbum(albumInfo)
        } else if let category = selectedCategory {
            return dataManager.getRealPhotos(for: category)
        } else if let timeGroupString = selectedTimeGroup,
                  let timeGroup = TimeGroup.allCases.first(where: { $0.rawValue == timeGroupString }) {
            return dataManager.getPhotosForTimeGroup(timeGroup)
        } else {
            return dataManager.photoLibraryManager.allPhotos
        }
    }
    
    private var totalPhotosCount: Int {
        return filteredRealPhotos.count
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 导航栏
                    navigationHeader
                    
                    // 主要照片区域
                    photoArea
                    
                    // 底部操作区域
                    bottomControls
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showBatchConfirm) {
            BatchConfirmView()
                .environmentObject(dataManager)
        }
        .onDisappear {
            // 离开页面时检查是否有待处理的操作
            if !dataManager.deleteCandidates.isEmpty || !dataManager.favoriteCandidates.isEmpty {
                showBatchConfirm = true
            }
        }
    }
    
    // MARK: - 导航栏
    private var navigationHeader: some View {
        HStack {
            // 返回按钮
            Button(action: handleBackAction) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.8))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            // 标题信息
            VStack(spacing: 2) {
                Text("照片整理")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text("\(getDisplayTitle()) · \(totalPhotosCount) 张照片")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 候选库统计
            VStack(alignment: .trailing, spacing: 2) {
                Text("待删除")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                
                Text("\(dataManager.deleteCandidates.count)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.black)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - 照片区域
    private var photoArea: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                if dataManager.photoLibraryManager.authorizationStatus != .authorized {
                    // 需要照片权限
                    VStack(spacing: 20) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Text("需要访问照片库")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("请允许访问您的照片库来开始整理照片")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Button(action: { 
                            dataManager.requestPhotoLibraryAccess()
                        }) {
                            Text("授权访问照片库")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                } else if let realPhoto = currentRealPhoto {
                    // 真实照片显示
                    ZStack {
                        RealPhotoCard(
                            asset: realPhoto, 
                            photoLibraryManager: dataManager.photoLibraryManager,
                            isInDeleteCandidates: dataManager.isInDeleteCandidates(realPhoto),
                            isInFavoriteCandidates: dataManager.isInFavoriteCandidates(realPhoto)
                        )
                        .frame(width: geometry.size.width - 48, height: 450)
                        .offset(dragOffset)
                        .rotationEffect(.degrees(rotationAngle))
                        .scaleEffect(1.0 - abs(dragOffset.width) / 1000)
                        .gesture(createDragGesture())
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: dragOffset)
                        
                        if abs(dragOffset.width) > 50 {
                            SwipeIndicator(direction: dragOffset.width < 0 ? .left : .right)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 没有更多照片
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundColor(.green)
                        
                        Text("整理完成！")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("您已经整理完所有照片")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.gray)
                        
                        Button(action: { dismiss() }) {
                            Text("返回主页")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                }
                
                // 操作提示
                if currentRealPhoto != nil {
                    HStack(spacing: 24) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                            Text("左滑加入删除候选")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.gray)
                        }
                        
                        Text("·")
                            .foregroundColor(.gray.opacity(0.5))
                        
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.green)
                            Text("右滑跳过")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.bottom, 20)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - 底部控制区域
    private var bottomControls: some View {
        VStack(spacing: 16) {
            // 功能按钮
            HStack(spacing: 0) {
                Spacer()
                
                // 撤销
                ActionButton(
                    icon: "arrow.uturn.backward",
                    title: "撤销",
                    color: .gray
                ) {
                    dataManager.undoLastAction()
                    resetCardPosition()
                }
                
                Spacer()
                
                // 收藏
                ActionButton(
                    icon: "heart.fill",
                    title: "收藏",
                    color: .pink
                ) {
                    dataManager.handleUpSwipe()
                    resetCardPosition()
                }
                
                Spacer()
                
                // 删除候选
                ActionButton(
                    icon: "trash",
                    title: "删除候选",
                    color: .red
                ) {
                    dataManager.handleLeftSwipe()
                    resetCardPosition()
                }
                
                Spacer()
                
                // 跳过
                ActionButton(
                    icon: "arrow.right",
                    title: "跳过",
                    color: .blue
                ) {
                    dataManager.handleRightSwipe()
                    resetCardPosition()
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.black)
    }
    
    // MARK: - 手势处理
    private func createDragGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
                rotationAngle = Double(value.translation.width / 20)
            }
            .onEnded { value in
                handleSwipeGesture(translation: value.translation)
            }
    }
    
    private func handleSwipeGesture(translation: CGSize) {
        let threshold: CGFloat = 100
        
        if abs(translation.width) > threshold {
            if translation.width < 0 {
                // 左滑：添加到删除候选库
                dataManager.handleLeftSwipe()
            } else {
                // 右滑：跳过
                dataManager.handleRightSwipe()
            }
        } else if abs(translation.height) > threshold {
            if translation.height < 0 {
                // 上滑：收藏
                dataManager.handleUpSwipe()
            } else {
                // 下滑：跳过
                dataManager.handleDownSwipe()
            }
        }
        
        resetCardPosition()
    }
    
    private func resetCardPosition() {
        dragOffset = .zero
        rotationAngle = 0
    }
    
    private func handleBackAction() {
        // 如果有待处理的操作，显示确认对话框
        if !dataManager.deleteCandidates.isEmpty || !dataManager.favoriteCandidates.isEmpty {
            showBatchConfirm = true
        } else {
            dismiss()
        }
    }
    
    private func getDisplayTitle() -> String {
        if let albumInfo = selectedAlbumInfo {
            return albumInfo.title
        } else if let category = selectedCategory {
            return category.rawValue
        } else if let timeGroup = selectedTimeGroup {
            return timeGroup
        } else {
            return "全部照片"
        }
    }
}

// MARK: - 真实照片卡片
struct RealPhotoCard: View {
    let asset: PHAsset
    let photoLibraryManager: PhotoLibraryManager
    let isInDeleteCandidates: Bool
    let isInFavoriteCandidates: Bool
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 350, height: 450)
                    .clipped()
                    .cornerRadius(16)
                    .overlay(
                        overlayContent,
                        alignment: .topTrailing
                    )
                    .overlay(
                        candidateOverlay,
                        alignment: .center
                    )
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.1, green: 0.1, blue: 0.15),
                                Color(red: 0.15, green: 0.15, blue: 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 350, height: 450)
                    .cornerRadius(16)
                    .overlay(
                        Group {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)
                            }
                        }
                    )
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: asset) { _, _ in
            loadImage()
        }
    }
    
    @ViewBuilder
    private var overlayContent: some View {
        VStack(spacing: 8) {
            if asset.mediaType == .video {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            
            if isScreenshot {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(12)
    }
    
    @ViewBuilder
    private var candidateOverlay: some View {
        if isInDeleteCandidates || isInFavoriteCandidates {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.7))
                
                VStack(spacing: 12) {
                    Image(systemName: isInDeleteCandidates ? "trash.fill" : "heart.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(isInDeleteCandidates ? .red : .pink)
                    
                    Text(isInDeleteCandidates ? "删除候选" : "收藏候选")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 350, height: 450)
            .cornerRadius(16)
        }
    }
    
    private var isScreenshot: Bool {
        if #available(iOS 9.0, *) {
            return asset.mediaSubtypes.contains(.photoScreenshot)
        }
        
        // 备用方法：通过尺寸判断
        let screenScale = UIScreen.main.scale
        let screenSize = UIScreen.main.bounds.size
        let screenPixelSize = CGSize(
            width: screenSize.width * screenScale,
            height: screenSize.height * screenScale
        )
        
        let assetSize = CGSize(width: CGFloat(asset.pixelWidth), height: CGFloat(asset.pixelHeight))
        
        return abs(assetSize.width - screenPixelSize.width) < 10 &&
               abs(assetSize.height - screenPixelSize.height) < 10
    }
    
    private func loadImage() {
        isLoading = true
        image = nil
        
        photoLibraryManager.loadImage(for: asset, size: CGSize(width: 350, height: 450)) { loadedImage in
            self.image = loadedImage
            self.isLoading = false
        }
    }
}

// MARK: - 滑动指示器
struct SwipeIndicator: View {
    let direction: SwipePhotoView.SwipeDirection
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: direction == .left ? "trash" : "arrow.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text(direction == .left ? "删除候选" : "跳过")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(direction == .left ? Color.red.opacity(0.9) : Color.blue.opacity(0.9))
        )
        .offset(x: direction == .left ? -100 : 100)
    }
}

// MARK: - 功能按钮
struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.8))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 批量确认视图
struct BatchConfirmView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(.green)
                    
                    Text("执行批量操作")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 8) {
                        if !dataManager.deleteCandidates.isEmpty {
                            Text("删除 \(dataManager.deleteCandidates.count) 张照片")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.red)
                        }
                        
                        if !dataManager.favoriteCandidates.isEmpty {
                            Text("收藏 \(dataManager.favoriteCandidates.count) 张照片")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.pink)
                        }
                    }
                }
                
                VStack(spacing: 12) {
                    Button(action: executeBatchOperations) {
                        Text("确认执行")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    
                    Button(action: cancelOperations) {
                        Text("取消操作")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 32)
        }
    }
    
    private func executeBatchOperations() {
        dataManager.executeBatchOperations { success, error in
            if success {
                dismiss()
            } else {
                // 处理错误
                print("批量操作失败: \(error?.localizedDescription ?? "未知错误")")
            }
        }
    }
    
    private func cancelOperations() {
        dataManager.cancelAllOperations()
        dismiss()
    }
}

#Preview {
    SwipePhotoView(selectedCategory: PhotoCategory.all, selectedTimeGroup: nil, selectedAlbumInfo: nil)
        .environmentObject(DataManager())
} 