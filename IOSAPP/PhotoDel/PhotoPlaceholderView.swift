//
//  PhotoPlaceholderView.swift
//  PhotoDel
//
//  Created by PhotoDel Team on 11/7/25.
//

import SwiftUI

struct PhotoPlaceholderView: View {
    let photo: Photo
    let width: CGFloat
    let height: CGFloat
    
    private var gradientColors: [Color] {
        // 根据照片名称生成不同的渐变色
        let seed = abs(photo.imageName.hashValue)
        let colorSets: [[Color]] = [
            [.blue, .purple, .pink],
            [.green, .teal, .cyan],
            [.orange, .red, .pink],
            [.purple, .indigo, .blue],
            [.yellow, .orange, .red],
            [.mint, .green, .blue],
            [.pink, .purple, .blue],
            [.teal, .blue, .indigo]
        ]
        return colorSets[seed % colorSets.count]
    }
    
    var body: some View {
        ZStack {
            // 渐变背景
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // 叠加纹理
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.1), Color.black.opacity(0.1)],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: max(width, height)
                    )
                )
            
            // 照片图标和信息
            VStack(spacing: 12) {
                // 照片/视频图标
                Image(systemName: photo.isVideo ? "video.fill" : "photo.fill")
                    .font(.system(size: min(width, height) * 0.15, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                
                // 照片名称
                Text(photo.imageName)
                    .font(.system(size: min(width, height) * 0.04, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                
                // 文件大小
                Text(String(format: "%.1f MB", photo.fileSize))
                    .font(.system(size: min(width, height) * 0.03, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // 视频标识
            if photo.isVideo {
                VStack {
                    HStack {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "play.fill")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 8)
                        .padding(.trailing, 8)
                    }
                    
                    Spacer()
                }
            }
            
            // 收藏标识
            if photo.status == .favorited {
                VStack {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.red)
                        }
                        .padding(.top, 8)
                        .padding(.leading, 8)
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
            }
        }
        .frame(width: width, height: height)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 小型照片缩略图
struct PhotoThumbnailView: View {
    let photo: Photo
    let size: CGFloat = 40
    
    var body: some View {
        PhotoPlaceholderView(photo: photo, width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
            )
    }
}

#Preview {
    VStack(spacing: 20) {
        PhotoPlaceholderView(
            photo: Photo(imageName: "sample1", isVideo: false),
            width: 300,
            height: 400
        )
        
        PhotoPlaceholderView(
            photo: Photo(imageName: "video1", isVideo: true),
            width: 300,
            height: 400
        )
        
        HStack(spacing: 12) {
            PhotoThumbnailView(photo: Photo(imageName: "thumb1"))
            PhotoThumbnailView(photo: Photo(imageName: "thumb2", status: .favorited))
            PhotoThumbnailView(photo: Photo(imageName: "thumb3", isVideo: true))
        }
    }
    .padding()
    .background(Color.black)
} 