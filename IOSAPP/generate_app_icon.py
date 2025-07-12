#!/usr/bin/env python3
"""
PhotoDel App Icon Generator
生成PhotoDel应用的图标，包含多个尺寸
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_app_icon(size=1024):
    """创建PhotoDel应用图标"""
    # 创建画布
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # 计算相对尺寸
    margin = size * 0.1  # 10% 边距
    inner_size = size - 2 * margin
    
    # 背景渐变 - 深蓝到紫色
    for y in range(size):
        # 从深蓝 #1E3A8A 到紫色 #7C3AED 的渐变
        ratio = y / size
        r = int(30 + (124 - 30) * ratio)
        g = int(58 + (58 - 58) * ratio)  
        b = int(138 + (237 - 138) * ratio)
        color = (r, g, b, 255)
        draw.line([(0, y), (size, y)], fill=color)
    
    # 圆角矩形背景
    corner_radius = size * 0.22  # 22% 圆角
    draw.rounded_rectangle([0, 0, size, size], radius=corner_radius, fill=None, outline=None)
    
    # 主要图标元素：相机图标结合删除符号
    center_x, center_y = size // 2, size // 2
    
    # 相机机身 
    camera_width = inner_size * 0.7
    camera_height = camera_width * 0.6
    camera_x = center_x - camera_width // 2
    camera_y = center_y - camera_height // 2 + size * 0.05  # 稍微向下偏移
    
    # 相机机身 - 白色半透明
    draw.rounded_rectangle(
        [camera_x, camera_y, camera_x + camera_width, camera_y + camera_height],
        radius=size * 0.05,
        fill=(255, 255, 255, 200)
    )
    
    # 相机镜头
    lens_radius = camera_width * 0.25
    lens_center_x = center_x
    lens_center_y = camera_y + camera_height * 0.6
    
    # 外圈镜头 - 深灰色
    draw.ellipse(
        [lens_center_x - lens_radius, lens_center_y - lens_radius,
         lens_center_x + lens_radius, lens_center_y + lens_radius],
        fill=(60, 60, 60, 255)
    )
    
    # 内圈镜头 - 黑色
    inner_lens_radius = lens_radius * 0.7
    draw.ellipse(
        [lens_center_x - inner_lens_radius, lens_center_y - inner_lens_radius,
         lens_center_x + inner_lens_radius, lens_center_y + inner_lens_radius],
        fill=(30, 30, 30, 255)
    )
    
    # 相机闪光灯
    flash_radius = size * 0.025
    flash_x = camera_x + camera_width * 0.2
    flash_y = camera_y + camera_height * 0.25
    draw.ellipse(
        [flash_x - flash_radius, flash_y - flash_radius,
         flash_x + flash_radius, flash_y + flash_radius],
        fill=(255, 255, 255, 255)
    )
    
    # 删除/整理符号 - 在右上角
    delete_size = size * 0.25
    delete_x = size - delete_size - margin * 0.5
    delete_y = margin * 0.5
    
    # 删除符号背景 - 红色圆形
    delete_radius = delete_size * 0.4
    delete_center_x = delete_x + delete_size // 2
    delete_center_y = delete_y + delete_size // 2
    
    draw.ellipse(
        [delete_center_x - delete_radius, delete_center_y - delete_radius,
         delete_center_x + delete_radius, delete_center_y + delete_radius],
        fill=(239, 68, 68, 255)  # 红色
    )
    
    # 删除符号 - 白色X
    line_width = int(size * 0.008)
    x_size = delete_radius * 0.6
    draw.line(
        [delete_center_x - x_size, delete_center_y - x_size,
         delete_center_x + x_size, delete_center_y + x_size],
        fill=(255, 255, 255, 255), width=line_width
    )
    draw.line(
        [delete_center_x - x_size, delete_center_y + x_size,
         delete_center_x + x_size, delete_center_y - x_size],
        fill=(255, 255, 255, 255), width=line_width
    )
    
    # 添加光泽效果
    overlay = Image.new('RGBA', (size, size), (255, 255, 255, 0))
    overlay_draw = ImageDraw.Draw(overlay)
    
    # 顶部高光
    overlay_draw.ellipse(
        [size * 0.1, size * 0.05, size * 0.6, size * 0.4],
        fill=(255, 255, 255, 20)
    )
    
    img = Image.alpha_composite(img, overlay)
    
    return img

def generate_all_sizes():
    """生成所有需要的图标尺寸"""
    sizes = [1024, 512, 256, 180, 167, 152, 120, 87, 80, 76, 60, 58, 40, 29, 20]
    
    # 创建输出目录
    output_dir = "PhotoDel/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(output_dir, exist_ok=True)
    
    print("🎨 正在生成PhotoDel应用图标...")
    
    for size in sizes:
        print(f"   生成 {size}x{size} 图标...")
        icon = create_app_icon(size)
        
        # 保存不同密度的图标
        if size >= 180:
            # 大尺寸图标，保存多个密度
            icon.save(f"{output_dir}/icon_{size}x{size}.png", "PNG")
            
            # @2x 版本
            icon_2x = create_app_icon(size * 2)
            icon_2x = icon_2x.resize((size, size), Image.Resampling.LANCZOS)
            icon_2x.save(f"{output_dir}/icon_{size}x{size}@2x.png", "PNG")
            
            # @3x 版本 (仅适用于某些尺寸)
            if size in [180, 120, 87, 60, 40, 29, 20]:
                icon_3x = create_app_icon(size * 3)
                icon_3x = icon_3x.resize((size, size), Image.Resampling.LANCZOS)
                icon_3x.save(f"{output_dir}/icon_{size}x{size}@3x.png", "PNG")
        else:
            icon.save(f"{output_dir}/icon_{size}x{size}.png", "PNG")
    
    # 创建主图标 (1024x1024)
    main_icon = create_app_icon(1024)
    main_icon.save(f"{output_dir}/Icon-1024.png", "PNG")
    
    print("✅ 所有图标已生成完成！")
    print(f"📁 图标文件保存在: {output_dir}/")
    print("\n🔧 下一步：")
    print("1. 在Xcode中打开PhotoDel.xcodeproj")
    print("2. 选择Assets.xcassets中的AppIcon")
    print("3. 将生成的图标文件拖拽到对应的尺寸槽位中")

if __name__ == "__main__":
    try:
        generate_all_sizes()
    except ImportError:
        print("❌ 缺少PIL库，请安装：pip install Pillow")
    except Exception as e:
        print(f"❌ 生成图标时出错：{e}") 