import os
import cv2 as cv
import numpy as np
import pydicom


def main():
    import argparse
    parser = argparse.ArgumentParser(description='Convert DICOM files to JPG.')
    parser.add_argument('--input', type=str, required=False, default='input_img', help='Input directory containing DICOM files')
    parser.add_argument('--output', type=str, required=False, default='output_img', help='Output directory for JPG files')
    parser.add_argument('--files', nargs='+', help='Specific DICOM files to convert')
    parser.add_argument('--format', type=str, choices=['jpg', 'png'], default='jpg', help='Output image format')
    args = parser.parse_args()

    input_dir = args.input
    output_dir = args.output
    specific_files = args.files
    output_ext = f".{args.format}"

    # Create output directory if it doesn't exist
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"Created directory: {output_dir}")

    dcm_files = []
    
    if specific_files:
        # Use provided file paths directly
        dcm_files = [f for f in specific_files if os.path.isfile(f)]
        if not dcm_files:
            print("None of the specified files exist.")
            return
    else:
        # List all files in input directory
        if not os.path.exists(input_dir):
            print(f"Input directory does not exist: {input_dir}")
            return
        
        files = [f for f in os.listdir(input_dir) if os.path.isfile(os.path.join(input_dir, f))]
        
        # Filter for DICOM files
        ignored_extensions = ['.gitkeep', '.txt', '.jpg', '.png', '.md', '.py', '.json']
        for f in files:
            if any(f.lower().endswith(ext) for ext in ignored_extensions):
                continue
            dcm_files.append(os.path.join(input_dir, f))

    if not dcm_files:
        print(f"No valid images found.")
        return

    count = 0
    for input_path in dcm_files:
        file = os.path.basename(input_path)
        
        # Determine output filename
        filename_no_ext = os.path.splitext(file)[0]
        output_filename = filename_no_ext + output_ext
        output_path = os.path.join(output_dir, output_filename)

        # Attempt conversion with force=True for non-standard DICOMs
        try:
            ds = pydicom.dcmread(input_path, force=True)
            if not hasattr(ds, 'pixel_array'):
                 print(f"Skipping {file}: No pixel data found.")
                 continue
                 
            if dcm_to_jpg_logic(ds, output_path):
                count += 1
        except Exception as e:
            print(f"Failed to read {file}: {e}")
            
    print(f"\nProcessing complete. Converted {count} files.")

def dcm_to_jpg_logic(ds, output_path):
    try:
        pixel_array = ds.pixel_array
        # Apply Windowing if tags are present
        if 'WindowCenter' in ds and 'WindowWidth' in ds:
            window_center = ds.WindowCenter
            window_width = ds.WindowWidth
            
            # Handle list/multivalues
            if isinstance(window_center, (list, pydicom.multival.MultiValue)):
                window_center = window_center[0]
            if isinstance(window_width, (list, pydicom.multival.MultiValue)):
                window_width = window_width[0]

            window_center = float(window_center)
            window_width = float(window_width)

            img_min = window_center - window_width / 2
            img_max = window_center + window_width / 2
            
            pixel_array = np.clip(pixel_array, img_min, img_max)
            # Normalize to 0-255 based on window
            if img_max != img_min:
                pixel_array = ((pixel_array - img_min) / (img_max - img_min)) * 255.0
            else:
                pixel_array = np.zeros_like(pixel_array)

        else:
            # Min-Max Normalization fallback
            img_min = np.min(pixel_array)
            img_max = np.max(pixel_array)
            if img_max != img_min:
                pixel_array = ((pixel_array - img_min) / (img_max - img_min)) * 255.0
            else:
                pixel_array = np.zeros_like(pixel_array)

        pixel_array = pixel_array.astype(np.uint8)

        # Handle Photometric Interpretation
        if 'PhotometricInterpretation' in ds:
            if ds.PhotometricInterpretation == 'MONOCHROME1':
                pixel_array = 255 - pixel_array

        # Save with maximum quality settings
        if output_path.lower().endswith(('.jpg', '.jpeg')):
            cv.imwrite(output_path, pixel_array, [int(cv.IMWRITE_JPEG_QUALITY), 100])
        elif output_path.lower().endswith('.png'):
            # PNG is lossless, but 0 compression means faster save, larger file. 
            # 9 means max compression (still lossless), smaller file. 
            # We'll use default compression (3) as it's a good balance, quality is same.
            cv.imwrite(output_path, pixel_array, [int(cv.IMWRITE_PNG_COMPRESSION), 1]) 
        else:
            cv.imwrite(output_path, pixel_array)

        print(f"Success: {output_path}")
        return True

    except Exception as e:
        print(f"Logic failure: {e}")
        return False

if __name__ == "__main__":
    main()
