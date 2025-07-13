//
//  SplashView.swift
//  PhotoDel
//
//  Created by PhotoDel Team on 11/7/25.
//

import SwiftUI

struct SplashView: View {
    @State private var showMainApp = false
    @State private var animateIcon = false
    
    var body: some View {
        ZStack {
            // 黑色背景
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // App图标
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "camera")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(.black)
                }
                .scaleEffect(animateIcon ? 1.0 : 0.9)
                .opacity(animateIcon ? 1.0 : 0.8)
                .animation(.easeOut(duration: 0.6), value: animateIcon)
                
                // App名称和标语
                VStack(spacing: 8) {
                    Text("PhotoDel")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("照片整理助手")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.gray)
                }
                .opacity(animateIcon ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: animateIcon)
                
                Spacer()
            }
        }
        .onAppear {
            // 简单动画后快速跳转
            animateIcon = true
            
            // 0.8秒后直接跳转到主应用
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showMainApp = true
            }
        }
        .fullScreenCover(isPresented: $showMainApp) {
            MainTabView()
        }
    }
}

#Preview {
    SplashView()
} 