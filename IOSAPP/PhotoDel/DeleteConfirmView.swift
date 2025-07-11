//
//  DeleteConfirmView.swift
//  PhotoDel
//
//  Created by PhotoDel Team on 11/7/25.
//

import SwiftUI

struct DeleteConfirmView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var showAnimation = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // 主要内容
                VStack(spacing: 32) {
                    // 删除图标
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "trash")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(showAnimation ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showAnimation)
                    
                    // 标题和描述
                    VStack(spacing: 12) {
                        Text("整理完成")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("以下是本次整理的统计信息")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.gray)
                    }
                    .opacity(showAnimation ? 1.0 : 0.0)
                    .offset(y: showAnimation ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: showAnimation)
                    
                    // 统计信息
                    statsGrid
                    
                    // 详细信息
                    detailsSection
                    
                    // 操作按钮
                    actionButtons
                    
                    // 提示信息
                    InfoBanner()
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
                .scaleEffect(showAnimation ? 1.0 : 0.9)
                .opacity(showAnimation ? 1.0 : 0.0)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1), value: showAnimation)
                
                Spacer()
            }
        }
        .onAppear {
            showAnimation = true
        }
    }
    
    // MARK: - 统计网格
    private var statsGrid: some View {
        HStack(spacing: 16) {
            StatisticCard(
                value: "\(dataManager.organizeStats.deletedPhotos)",
                label: "已删除",
                color: .red
            )
            
            StatisticCard(
                value: "\(dataManager.organizeStats.keptPhotos)",
                label: "已保留",
                color: .green
            )
        }
        .opacity(showAnimation ? 1.0 : 0.0)
        .offset(y: showAnimation ? 0 : 30)
        .animation(.easeOut(duration: 0.8).delay(0.4), value: showAnimation)
    }
    
    // MARK: - 详细信息
    private var detailsSection: some View {
        VStack(spacing: 12) {
            DetailRow(
                label: "释放空间",
                value: dataManager.organizeStats.formattedSpaceSaved
            )
            
            DetailRow(
                label: "整理时间",
                value: dataManager.organizeStats.formattedTimeSpent
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
        .opacity(showAnimation ? 1.0 : 0.0)
        .offset(y: showAnimation ? 0 : 30)
        .animation(.easeOut(duration: 0.8).delay(0.6), value: showAnimation)
    }
    
    // MARK: - 操作按钮
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 确认删除按钮
            Button(action: confirmDeletion) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("确认删除")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red)
                .cornerRadius(12)
            }
            
            // 取消删除按钮
            Button(action: cancelDeletion) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("取消删除")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
            }
        }
        .opacity(showAnimation ? 1.0 : 0.0)
        .offset(y: showAnimation ? 0 : 30)
        .animation(.easeOut(duration: 0.8).delay(0.8), value: showAnimation)
    }
    
    // MARK: - 操作方法
    private func confirmDeletion() {
        dataManager.confirmDeletion()
        dismiss()
    }
    
    private func cancelDeletion() {
        dataManager.cancelDeletion()
        dismiss()
    }
}

// MARK: - 统计卡片
struct StatisticCard: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - 详细信息行
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - 提示信息视图
struct InfoBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray.opacity(0.8))
            
            Text("删除的照片将移至回收站，30天后永久删除")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.gray.opacity(0.8))
        }
        .padding(.top, 16)
    }
}

#Preview {
    DeleteConfirmView()
        .environmentObject(DataManager())
} 