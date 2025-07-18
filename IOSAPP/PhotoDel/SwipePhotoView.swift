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
    let selectedTimeGroup: TimeGroup?
    
    @State private var dragOffset = CGSize.zero
    @State private var rotationAngle: Double = 0
    @State private var showDeleteConfirm = false
    @State private var swipeDirection: SwipeDirection?
    @State private var showPhotoAccessAlert = false
    
    enum SwipeDirection {
        case left, right, up, down
    }
    
    private var currentPhoto: Photo? {
        return dataManager.useRealPhotos ? nil : dataManager.getCurrentPhoto()
    }
    
    private var currentRealPhoto: PHAsset? {
        return dataManager.useRealPhotos ? dataManager.getCurrentRealPhoto() : nil
    }
    
    private var filteredPhotos: [Photo] {
        if dataManager.useRealPhotos { return [] }
        
        if let category = selectedCategory {
            return dataManager.getPhotos(for: category)
        } else if let timeGroup = selectedTimeGroup {
            return dataManager.getPhotos(for: timeGroup)
        } else {
            return dataManager.photos
        }
    }
    
    private var filteredRealPhotos: [PHAsset] {
        guard dataManager.useRealPhotos else { return [] }
        
        if let category = selectedCategory {
            return dataManager.getRealPhotos(for: category)
        } else {
            return dataManager.photoLibraryManager.allPhotos
        }
    }
    
    private var totalPhotosCount: Int {
        return dataManager.useRealPhotos ? filteredRealPhotos.count : filteredPhotos.count
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
        .sheet(isPresented: $showDeleteConfirm) {
            DeleteConfirmView()
                .environmentObject(dataManager)
        }
    }
    
    // MARK: - 导航栏
    private var navigationHeader: some View {
        HStack {
            // 返回按钮
            Button(action: { dismiss() }) {
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
                
                Text("\(selectedCategory?.rawValue ?? selectedTimeGroup?.rawValue ?? "全部相册") · \(totalPhotosCount) 张照片")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 已删除统计
            VStack(alignment: .trailing, spacing: 2) {
                Text("已删除")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                
                Text("\(dataManager.organizeStats.deletedPhotos)")
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
                
                if let photo = currentPhoto {
                    // 虚拟照片显示
                    ZStack {
                        PhotoCard(photo: photo)
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
                } else if let realPhoto = currentRealPhoto {
                    // 真实照片显示
                    ZStack {
                        RealPhotoCard(asset: realPhoto, photoLibraryManager: dataManager.photoLibraryManager)
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
                } else if dataManager.useRealPhotos && dataManager.photoLibraryManager.authorizationStatus != .authorized {
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
                } else {
                    // 没有更多照片
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundColor(.green)
                        
                        Text("整理完成！")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("所有照片都已处理完毕")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.gray)
                        
                        Button(action: { showDeleteConfirm = true }) {
                            Text("查看整理结果")
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
                if currentPhoto != nil {
                    HStack(spacing: 24) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                            Text("左滑删除")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.gray)
                        }
                        
                        Text("·")
                            .foregroundColor(.gray.opacity(0.5))
                        
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.green)
                            Text("右滑保留")
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
            // 相册选择器
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(dataManager.albums) { album in
                        AlbumButton(album: album)
                    }
                }
                .padding(.horizontal, 24)
            }
            
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
                }
                
                Spacer()
                
                // 收藏
                ActionButton(
                    icon: "heart.fill",
                    title: "收藏",
                    color: .pink
                ) {
                    if dataManager.useRealPhotos {
                        dataManager.favoriteCurrentRealPhoto()
                    } else {
                        dataManager.favoriteCurrentPhoto()
                    }
                    resetCardPosition()
                }
                
                Spacer()
                
                // 删除
                ActionButton(
                    icon: "trash",
                    title: "删除",
                    color: .red
                ) {
                    if dataManager.useRealPhotos {
                        dataManager.deleteCurrentRealPhoto()
                    } else {
                        dataManager.deleteCurrentPhoto()
                    }
                    resetCardPosition()
                }
                
                Spacer()
                
                // 设置
                ActionButton(
                    icon: "gearshape",
                    title: "设置",
                    color: .gray
                ) {
                    // 打开设置
                }
                
                Spacer()
            }
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.05))
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // MARK: - 手势处理
    private func createDragGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
                rotationAngle = Double(value.translation.width / 10)
            }
            .onEnded { value in
                handleSwipeGesture(translation: value.translation)
            }
    }
    
    private func handleSwipeGesture(translation: CGSize) {
        let threshold: CGFloat = 100
        
        if abs(translation.width) > threshold {
            if translation.width < 0 {
                // 左滑删除
                if dataManager.useRealPhotos {
                    dataManager.deleteCurrentRealPhoto()
                } else {
                    dataManager.deleteCurrentPhoto()
                }
            } else {
                // 右滑保留
                if dataManager.useRealPhotos {
                    dataManager.moveToNextRealPhoto()
                } else {
                    dataManager.keepCurrentPhoto()
                }
            }
        } else if abs(translation.height) > threshold {
            if translation.height < 0 {
                // 上滑收藏
                if dataManager.useRealPhotos {
                    dataManager.favoriteCurrentRealPhoto()
                } else {
                    dataManager.favoriteCurrentPhoto()
                }
            } else {
                // 下滑跳过
                if dataManager.useRealPhotos {
                    dataManager.skipCurrentRealPhoto()
                } else {
                    dataManager.skipCurrentPhoto()
                }
            }
        }
        
        resetCardPosition()
    }
    
    private func resetCardPosition() {
        dragOffset = .zero
        rotationAngle = 0
    }
}

// MARK: - 照片卡片
struct PhotoCard: View {
    let photo: Photo
    
    var body: some View {
        ZStack {
            // 使用PhotoPlaceholderView显示照片
            PhotoPlaceholderView(photo: photo, width: 350, height: 450)
            
            // 底部信息覆盖层
            VStack {
                Spacer()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(photo.formattedDate)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            Text(photo.device)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.white.opacity(0.8))
                            
                            if let location = photo.location {
                                Text("· \(location)")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }
}

// MARK: - 真实照片卡片
struct RealPhotoCard: View {
    let asset: PHAsset
    let photoLibraryManager: PhotoLibraryManager
    
    var body: some View {
        ZStack {
            // 显示真实照片
            RealPhotoView(
                asset: asset, 
                photoLibraryManager: photoLibraryManager, 
                size: CGSize(width: 350, height: 450)
            )
            
            // 底部信息覆盖层
            VStack {
                Spacer()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatDate(asset.creationDate))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            Text("真实照片")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.white.opacity(0.8))
                            
                            if asset.mediaType == .video {
                                Text("· 视频")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            if asset.isFavorite {
                                Text("· 已收藏")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.red.opacity(0.8))
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "未知日期" }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 滑动指示器
struct SwipeIndicator: View {
    let direction: SwipePhotoView.SwipeDirection
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: direction == .left ? "trash" : "heart.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text(direction == .left ? "删除" : "保留")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(direction == .left ? Color.red.opacity(0.9) : Color.green.opacity(0.9))
        )
        .offset(x: direction == .left ? -100 : 100)
    }
}

// MARK: - 相册按钮
struct AlbumButton: View {
    let album: Album
    
    var body: some View {
        VStack(spacing: 4) {
            Text(album.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

// MARK: - 操作按钮
struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 60, height: 60)
    }
}

#Preview {
    SwipePhotoView(selectedCategory: .all, selectedTimeGroup: nil)
        .environmentObject(DataManager())
} 