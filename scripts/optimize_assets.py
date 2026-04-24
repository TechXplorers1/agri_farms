import os
from PIL import Image

def optimize_images(directory):
    total_original_size = 0
    total_new_size = 0
    files_processed = 0

    if not os.path.exists(directory):
        print(f"Directory {directory} does not exist.")
        return

    for filename in os.listdir(directory):
        if filename.endswith(".png"):
            file_path = os.path.join(directory, filename)
            original_size = os.path.getsize(file_path)
            total_original_size += original_size

            # Open image
            with Image.open(file_path) as img:
                # Construct new filename
                new_filename = os.path.splitext(filename)[0] + ".webp"
                new_path = os.path.join(directory, new_filename)
                
                # Save as WebP with high quality
                # quality=90 is usually plenty for mobile screens
                img.save(new_path, "WEBP", quality=90, method=6)
                
                new_size = os.path.getsize(new_path)
                total_new_size += new_size
                files_processed += 1
                
                print(f"Compressed {filename}: {original_size/1024:.1f}KB -> {new_size/1024:.1f}KB")

            # Delete original PNG
            os.remove(file_path)

    if files_processed > 0:
        print("\nOptimization Summary:")
        print(f"Files Processed: {files_processed}")
        print(f"Original Size: {total_original_size / (1024*1024):.2f} MB")
        print(f"New Size: {total_new_size / (1024*1024):.2f} MB")
        reduction = (1 - total_new_size / total_original_size) * 100
        print(f"Reduction: {reduction:.1f}%")

if __name__ == "__main__":
    assets_dir = os.path.join("assets", "images")
    optimize_images(assets_dir)
