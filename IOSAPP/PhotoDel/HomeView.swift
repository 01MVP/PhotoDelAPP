//
//  HomeView.swift
//  PhotoDel
//
//  Created by PhotoDel Team on 11/7/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showSwipeView = false
    @State private var selectedCategory: PhotoCategory?
    @State private var selectedTimeGroup: TimeGroup?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 顶部标题
                        VStack(spacing: 8) {
                            Text("PhotoDel")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("选择分类开始整理")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)
                        
                        // 照片源切换
                        VStack(spacing: 12) {
                            HStack {
                                Text("照片源")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            
                            VStack(spacing: 8) {
                                // 虚拟照片选项
                                PhotoSourceOption(
                                    title: "虚拟照片演示",
                                    subtitle: "1,234张演示照片",
                                    icon: "photo.stack",
                                    isSelected: !dataManager.useRealPhotos
                                ) {
                                    dataManager.switchToVirtualPhotos()
                                }
                                
                                // 真实照片选项
                                PhotoSourceOption(
                                    title: "我的照片库",
                                    subtitle: dataManager.photoLibraryManager.authorizationStatus == .authorized ? 
                                        "\(dataManager.photoLibraryManager.totalPhotosCount)张真实照片" : "需要访问权限",
                                    icon: "photo.on.rectangle.angled",
                                    isSelected: dataManager.useRealPhotos,
                                    isEnabled: dataManager.photoLibraryManager.authorizationStatus == .authorized
                                ) {
                                    dataManager.switchToRealPhotos()
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // 照片分类部分
                        VStack(alignment: .leading, spacing: 12) {
                            Text("照片分类")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                                ForEach(PhotoCategory.allCases, id: \.self) { category in
                                    CategoryCard(
                                        category: category,
                                        count: getPhotoCount(for: category)
                                    ) {
                                        selectedCategory = category
                                        showSwipeView = true
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // 按时间浏览部分
                        VStack(alignment: .leading, spacing: 12) {
                            Text("按时间浏览")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 8) {
                                ForEach(TimeGroup.allCases, id: \.self) { timeGroup in
                                    TimeGroupCard(
                                        timeGroup: timeGroup,
                                        count: dataManager.getPhotoCount(for: timeGroup)
                                    ) {
                                        selectedTimeGroup = timeGroup
                                        showSwipeView = true
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // 底部安全区域
                        Spacer()
                            .frame(height: 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showSwipeView) {
            SwipePhotoView(
                selectedCategory: selectedCategory,
                selectedTimeGroup: selectedTimeGroup
            )
            .environmentObject(dataManager)
        }
    }
    
    // MARK: - Helper Methods
    private func getPhotoCount(for category: PhotoCategory) -> Int {
        if dataManager.useRealPhotos {
            switch category {
            case .all:
                return dataManager.photoLibraryManager.totalPhotosCount
            case .videos:
                return dataManager.photoLibraryManager.videosCount
            case .screenshots:
                return dataManager.photoLibraryManager.screenshotsCount
            case .favorites:
                return dataManager.photoLibraryManager.favoritesCount
            }
        } else {
            return dataManager.getPhotoCount(for: category)
        }
    }
}

// MARK: - 分类卡片
struct CategoryCard: View {
    let category: PhotoCategory
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // 图标
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(category.color)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: category.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    // 文字信息
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.rawValue)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("\(count)张")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
    }
}

// MARK: - 时间分组卡片
struct TimeGroupCard: View {
    let timeGroup: TimeGroup
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 图标
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(timeGroup.color)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: timeGroup.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // 文字信息
                VStack(alignment: .leading, spacing: 2) {
                    Text(timeGroup.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("\(count)张照片")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 进度圆环
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                        .frame(width: 32, height: 32)
                    
                    Circle()
                        .trim(from: 0, to: timeGroup.progress)
                        .stroke(timeGroup.progressColor, lineWidth: 3)
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: timeGroup.progress)
                }
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
    }
}

// MARK: - 照片源选择组件
struct PhotoSourceOption: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    var isEnabled: Bool = true
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 图标
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // 文字信息
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isEnabled ? .white : .gray)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 选择指示器
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding(12)
        }
        .disabled(!isEnabled)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(isSelected ? 0.15 : 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(DataManager())
} 