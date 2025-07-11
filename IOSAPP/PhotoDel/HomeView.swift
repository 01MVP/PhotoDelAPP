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
                                        count: dataManager.getPhotoCount(for: category)
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

#Preview {
    HomeView()
        .environmentObject(DataManager())
} 