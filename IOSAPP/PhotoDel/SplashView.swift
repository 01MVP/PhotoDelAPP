//
//  SplashView.swift
//  PhotoDel
//
//  Created by PhotoDel Team on 11/7/25.
//

import SwiftUI

struct SplashView: View {
    @State private var isLoading = true
    @State private var loadingProgress: Double = 0.0
    @State private var animateIcon = false
    @State private var animateText = false
    @State private var showMainApp = false
    
    var body: some View {
        ZStack {
            // 黑色背景
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // App图标
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .frame(width: 120, height: 120)
                        .border(Color.gray.opacity(0.3), width: 2)
                    
                    Image(systemName: "camera.retro")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(.black)
                }
                .scaleEffect(animateIcon ? 1.0 : 0.8)
                .opacity(animateIcon ? 1.0 : 0.0)
                .animation(.easeOut(duration: 1.0), value: animateIcon)
                
                // App名称和标语
                VStack(spacing: 8) {
                    Text("PhotoDel")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(animateText ? 1.0 : 0.0)
                        .offset(y: animateText ? 0 : 30)
                        .animation(.easeOut(duration: 1.0).delay(0.2), value: animateText)
                    
                    VStack(spacing: 4) {
                        Text("照片整理助手")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.gray)
                        Text("让你的相册井然有序")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.gray)
                    }
                    .opacity(animateText ? 1.0 : 0.0)
                    .offset(y: animateText ? 0 : 30)
                    .animation(.easeOut(duration: 1.0).delay(0.4), value: animateText)
                }
                .padding(.top, 24)
                
                Spacer()
                
                // 加载动画
                if isLoading {
                    VStack(spacing: 16) {
                        Text("正在启动...")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.gray)
                            .opacity(animateText ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 1.0).delay(0.6), value: animateText)
                        
                        // 加载进度条
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 200, height: 4)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white)
                                .frame(width: 200 * loadingProgress, height: 4)
                                .animation(.easeInOut(duration: 0.3), value: loadingProgress)
                        }
                        .opacity(animateText ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 1.0).delay(0.6), value: animateText)
                    }
                }
                
                Spacer()
                
                // 版本信息
                Text("Version 1.0.0")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.gray.opacity(0.6))
                    .opacity(animateText ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 1.0).delay(0.8), value: animateText)
                    .padding(.bottom, 32)
            }
        }
        .onAppear {
            startAnimations()
            startLoadingProgress()
        }
        .fullScreenCover(isPresented: $showMainApp) {
            MainTabView()
        }
    }
    
    private func startAnimations() {
        animateIcon = true
        animateText = true
    }
    
    private func startLoadingProgress() {
        // 模拟加载过程
        let timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if loadingProgress < 0.7 {
                loadingProgress += 0.02
            } else if loadingProgress < 1.0 {
                loadingProgress += 0.01
            } else {
                timer.invalidate()
                // 加载完成后等待0.5秒再跳转
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isLoading = false
                    showMainApp = true
                }
            }
        }
    }
}

#Preview {
    SplashView()
} 