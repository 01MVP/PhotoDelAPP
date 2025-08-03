# PhotoDel iOS 应用开发指南

## 项目结构
```
PhotoDelAPP/
├── IOSAPP/                    # iOS应用主目录
│   ├── PhotoDel/             # 应用源代码
│   │   ├── PhotoDelApp.swift # 应用入口
│   │   ├── HomeView.swift    # 主页视图
│   │   ├── SwipePhotoView.swift # 照片整理视图
│   │   ├── AlbumsView.swift  # 相册管理视图
│   │   ├── DataManager.swift # 数据管理器
│   │   └── ...
│   └── PhotoDel.xcodeproj/   # Xcode项目文件
└── Prototype/                # HTML原型
```

## 常用开发命令

### 1. 构建应用
```bash
cd IOSAPP
xcodebuild -project PhotoDel.xcodeproj -scheme PhotoDel -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' build
```

### 2. 启动模拟器
```bash
# 启动iPhone 16模拟器
xcrun simctl boot "iPhone 16"

# 查看可用的模拟器
xcrun simctl list devices
```

### 3. 安装和运行应用
```bash
# 安装应用到模拟器
xcrun simctl install "iPhone 16" /Users/jackiexiao/Library/Developer/Xcode/DerivedData/PhotoDel-*/Build/Products/Debug-iphonesimulator/PhotoDel.app

# 启动应用
xcrun simctl launch "iPhone 16" com.01MVP.PhotoDel

# 打开模拟器界面
open -a Simulator
```

### 4. 清理和重置
```bash
# 清理构建缓存
xcodebuild clean

# 重置模拟器
xcrun simctl erase "iPhone 16"
```

## 测试方法

### 1. 功能测试步骤
1. **权限测试**：首次启动应用，确认照片库权限请求正常
2. **主页测试**：
   - 点击"全部照片"卡片，确认能进入整理页面
   - 检查时间线数据显示是否正确
   - 验证进度计算是否基于实际整理状态
3. **照片整理测试**：
   - 测试收藏功能（空心桃变实心桃）
   - 测试删除候选功能
   - 测试用户相册快速归类按钮
   - 确认操作后自动跳转到下一张照片
4. **批量操作测试**：
   - 执行批量删除/收藏操作
   - 确认操作完成后返回主页
   - 验证主页数据更新是否及时
5. **相册管理测试**：
   - 创建新相册
   - 编辑相册名称
   - 删除用户创建的相册

### 2. 模拟器照片准备
在模拟器中添加测试照片：
1. 打开模拟器
2. 设备 → 照片 → 添加照片...
3. 选择测试图片添加到相册

### 3. 调试技巧
- 使用Xcode的控制台查看日志输出
- 检查权限状态：`dataManager.photoLibraryManager.authorizationStatus`
- 验证照片数量：`dataManager.photoLibraryManager.allPhotos.count`

## 关键配置

### Bundle Identifier
- 主应用：`com.01MVP.PhotoDel`
- 测试：`com.01MVP.PhotoDelTests`
- UI测试：`com.01MVP.PhotoDelUITests`

### 权限配置
应用需要以下权限：
- 照片库访问权限（NSPhotoLibraryUsageDescription）

### 支持的iOS版本
- 最低支持：iOS 14.0
- 推荐测试：iOS 18.5

## 常见问题解决

### 1. 构建失败
- 检查Xcode版本兼容性
- 清理构建缓存：`xcodebuild clean`
- 检查代码签名设置

### 2. 模拟器启动失败
- 确认模拟器名称正确
- 重置模拟器：`xcrun simctl erase "iPhone 16"`
- 重启Xcode和模拟器

### 3. 应用无法启动
- 检查Bundle Identifier是否正确
- 确认应用已正确安装到模拟器
- 查看控制台错误信息

### 4. 照片权限问题
- 在模拟器设置中手动授权照片访问
- 重置隐私设置：设置 → 通用 → 传输或还原iPhone → 抹掉所有内容和设置

## 代码架构说明

### 主要组件
- **DataManager**：数据管理中心，处理照片库操作和状态管理
- **PhotoLibraryManager**：照片库访问封装
- **HomeView**：主页界面，显示分类和时间线
- **SwipePhotoView**：照片整理界面，支持滑动操作
- **AlbumsView**：相册管理界面

### 数据流
1. PhotoLibraryManager 负责与系统照片库交互
2. DataManager 管理应用状态和业务逻辑
3. 各View通过 @EnvironmentObject 共享DataManager
4. 使用 @Published 属性实现响应式UI更新

## 发布准备

### 1. 版本检查
- 更新版本号
- 检查所有功能正常
- 运行完整测试套件

### 2. 构建发布版本
```bash
xcodebuild -project PhotoDel.xcodeproj -scheme PhotoDel -configuration Release archive
```

### 3. 提交App Store
- 使用Xcode Organizer
- 或使用Application Loader

---

**注意**：本文档应随项目更新而及时维护，确保开发流程的准确性。