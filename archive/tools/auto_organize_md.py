"""
MD文件自动整理脚本
每次运行完项目后，运行此脚本将新创建的md文件移动到md/文件夹中
按创建时间顺序排列
"""

import os
import glob
import shutil
from datetime import datetime

def organize_md_files():
    print("=" * 60)
    print("MD文件自动整理工具")
    print("=" * 60)

    # 确保md目录存在
    md_dir = "md"
    if not os.path.exists(md_dir):
        os.makedirs(md_dir)
        print(f"✓ 创建 {md_dir}/ 目录")

    # 获取根目录中的所有md文件（除了README.md）
    md_files = [f for f in glob.glob("*.md") if f != 'README.md']

    if not md_files:
        print("\n✓ 根目录中没有需要整理的md文件")
        return

    # 获取文件信息并按创建时间排序
    file_info = []
    for f in md_files:
        try:
            creation_time = os.path.getctime(f)
            file_info.append({
                'name': f,
                'creation_time': creation_time
            })
        except Exception as e:
            print(f"✗ 处理文件出错 {f}: {e}")

    # 按创建时间排序
    file_info.sort(key=lambda x: x['creation_time'])

    # 移动文件
    print(f"\n开始整理 {len(file_info)} 个文件...\n")
    moved_count = 0

    for item in file_info:
        old_path = item['name']
        new_path = os.path.join(md_dir, item['name'])

        try:
            if os.path.exists(old_path):
                shutil.move(old_path, new_path)
                moved_count += 1
                creation_date = datetime.fromtimestamp(item['creation_time']).strftime('%Y-%m-%d %H:%M:%S')
                print(f"[{moved_count:02d}] {creation_date} -> {item['name']}")
        except Exception as e:
            print(f"✗ 移动文件失败 {item['name']}: {e}")

    print("\n" + "=" * 60)
    print(f"✓ 整理完成！共移动 {moved_count} 个文件到 {md_dir}/ 目录")
    print("=" * 60)

    # 显示统计信息
    total_in_md = len(glob.glob(os.path.join(md_dir, "*.md")))
    print(f"\n当前 {md_dir}/ 目录共有 {total_in_md} 个md文件")

if __name__ == "__main__":
    organize_md_files()
