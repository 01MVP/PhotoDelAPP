//
//  AlbumsView.swift
//  PhotoDel
//
//  Created by PhotoDel Team on 11/7/25.
//

import SwiftUI

struct AlbumsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var searchText = ""
    @State private var showingAddAlbum = false
    @State private var editingAlbum: Album?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 顶部导航栏
                    navigationHeader
                    
                    // 搜索栏
                    searchBar
                    
                    // 相册列表
                    albumsList
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddAlbum) {
            AddAlbumView()
                .environmentObject(dataManager)
        }
        .sheet(item: $editingAlbum) { album in
            EditAlbumView(album: album)
                .environmentObject(dataManager)
        }
    }
    
    // MARK: - 导航栏
    private var navigationHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("相册")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("管理你的相册")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: { showingAddAlbum = true }) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.8))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
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
    
    // MARK: - 搜索栏
    private var searchBar: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                
                TextField("搜索相册...", text: $searchText)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white)
                    .accentColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.7), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            Color.black.opacity(0.9)
                .blur(radius: 10)
        )
    }
    
    // MARK: - 相册列表
    private var albumsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("我的相册")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                    
                    ForEach(filteredAlbums) { album in
                        AlbumRow(
                            album: album,
                            onEdit: { editingAlbum = album },
                            onDelete: { deleteAlbum(album) }
                        )
                        .padding(.horizontal, 24)
                    }
                }
                
                // 底部安全区域
                Spacer()
                    .frame(height: 100)
            }
        }
    }
    
    // MARK: - 计算属性
    private var filteredAlbums: [Album] {
        if searchText.isEmpty {
            return dataManager.albums
        } else {
            return dataManager.albums.filter { album in
                album.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - 方法
    private func deleteAlbum(_ album: Album) {
        guard let index = dataManager.albums.firstIndex(where: { $0.id == album.id }) else { return }
        dataManager.deleteAlbum(at: IndexSet(integer: index))
    }
}

// MARK: - 相册行
struct AlbumRow: View {
    let album: Album
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var showingActionButtons = false
    
    var body: some View {
        ZStack {
            // 背景操作按钮
            HStack {
                // 编辑按钮
                Button(action: onEdit) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                // 删除按钮
                Button(action: onDelete) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            .opacity(abs(dragOffset.width) > 20 ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: dragOffset)
            
            // 主要内容
            HStack(spacing: 12) {
                // 拖拽手柄
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(width: 20)
                
                // 相册缩略图
                if let coverPhoto = album.coverPhoto {
                    PhotoThumbnailView(photo: coverPhoto)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(album.color.opacity(0.8))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: album.icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                
                // 相册信息
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Image(systemName: album.icon)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(album.color)
                        
                        Text(album.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Text("\(album.photoCount)张照片")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 操作按钮
                HStack(spacing: 16) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: {
                        withAnimation {
                            onDelete()
                        }
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                                        if abs(value.translation.width) > 100 {
                    if value.translation.width > 0 {
                        onEdit()
                    } else {
                        onDelete()
                    }
                }
                        
                        withAnimation(.spring()) {
                            dragOffset = .zero
                        }
                    }
            )
        }
    }
}

// MARK: - 添加相册视图
struct AddAlbumView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var albumName = ""
    @State private var selectedIcon = "folder.fill"
    @State private var selectedColor = Color.blue
    
    private let availableIcons = [
        "folder.fill", "heart.fill", "star.fill", "tag.fill",
        "person.2.fill", "airplane", "car.fill", "house.fill",
        "briefcase.fill", "gamecontroller.fill", "music.note",
        "camera.fill", "book.fill", "paintbrush.fill"
    ]
    
    private let availableColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal,
        .cyan, .blue, .indigo, .purple, .pink, .brown
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // 预览
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedColor)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: selectedIcon)
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Text(albumName.isEmpty ? "新相册" : albumName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 40)
                    
                    // 表单
                    VStack(spacing: 20) {
                        // 相册名称
                        VStack(alignment: .leading, spacing: 8) {
                            Text("相册名称")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            TextField("输入相册名称", text: $albumName)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.white)
                                .accentColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                        
                        // 图标选择
                        VStack(alignment: .leading, spacing: 8) {
                            Text("选择图标")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                                ForEach(availableIcons, id: \.self) { icon in
                                    Button(action: { selectedIcon = icon }) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedIcon == icon ? selectedColor : Color.gray.opacity(0.3))
                                                .frame(width: 40, height: 40)
                                            
                                            Image(systemName: icon)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // 颜色选择
                        VStack(alignment: .leading, spacing: 8) {
                            Text("选择颜色")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                ForEach(Array(availableColors.enumerated()), id: \.offset) { index, color in
                                    Button(action: { selectedColor = color }) {
                                        ZStack {
                                            Circle()
                                                .fill(color)
                                                .frame(width: 40, height: 40)
                                            
                                            if selectedColor == color {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationTitle("新建相册")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        if !albumName.isEmpty {
                            dataManager.addAlbum(
                                name: albumName,
                                icon: selectedIcon,
                                color: selectedColor
                            )
                            dismiss()
                        }
                    }
                    .foregroundColor(albumName.isEmpty ? .gray : .blue)
                    .disabled(albumName.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - 编辑相册视图
struct EditAlbumView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    let album: Album
    @State private var albumName: String
    @State private var selectedIcon: String
    @State private var selectedColor: Color
    
    init(album: Album) {
        self.album = album
        self._albumName = State(initialValue: album.name)
        self._selectedIcon = State(initialValue: album.icon)
        self._selectedColor = State(initialValue: album.color)
    }
    
    var body: some View {
        // 编辑相册的实现与添加相册类似，这里简化处理
        Text("编辑相册功能")
            .foregroundColor(.white)
            .onAppear {
                dismiss()
            }
    }
}

#Preview {
    AlbumsView()
        .environmentObject(DataManager())
} 