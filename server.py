import os
import io
import cv2 as cv
import numpy as np
import pydicom
from flask import Flask, request, send_file, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app) # Enable CORS for Flutter Web

def dcm_to_image_data(dcm_bytes):
    try:
        # Load from bytes
        with io.BytesIO(dcm_bytes) as f:
            ds = pydicom.dcmread(f, force=True)
        
        pixel_array = ds.pixel_array

        # Apply Windowing
        if 'WindowCenter' in ds and 'WindowWidth' in ds:
            window_center = ds.WindowCenter
            window_width = ds.WindowWidth
            
            if isinstance(window_center, (list, pydicom.multival.MultiValue)):
                window_center = window_center[0]
            if isinstance(window_width, (list, pydicom.multival.MultiValue)):
                window_width = window_width[0]

            window_center = float(window_center)
            window_width = float(window_width)

            img_min = window_center - window_width / 2
            img_max = window_center + window_width / 2
            
            pixel_array = np.clip(pixel_array, img_min, img_max)
            if img_max != img_min:
                pixel_array = ((pixel_array - img_min) / (img_max - img_min)) * 255.0
            else:
                pixel_array = np.zeros_like(pixel_array)
        else:
            img_min = np.min(pixel_array)
            img_max = np.max(pixel_array)
            if img_max != img_min:
                pixel_array = ((pixel_array - img_min) / (img_max - img_min)) * 255.0
            else:
                pixel_array = np.zeros_like(pixel_array)

        pixel_array = pixel_array.astype(np.uint8)

        if 'PhotometricInterpretation' in ds:
            if ds.PhotometricInterpretation == 'MONOCHROME1':
                pixel_array = 255 - pixel_array

        # Encode to JPEG
        is_success, buffer = cv.imencode(".jpg", pixel_array)
        if not is_success:
            return None
        
        return io.BytesIO(buffer).getvalue()

    except Exception as e:
        print(f"Error: {e}")
        return None

@app.route('/convert', methods=['POST'])
def convert():
    if 'file' not in request.files:
        return jsonify({"error": "No file uploaded"}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "Empty filename"}), 400

    dcm_bytes = file.read()
    jpg_bytes = dcm_to_image_data(dcm_bytes)

    if jpg_bytes is None:
        return jsonify({"error": "Failed to convert DICOM"}), 500

    return send_file(
        io.BytesIO(jpg_bytes),
        mimetype='image/jpeg',
        as_attachment=True,
        download_name='converted.jpg'
    )

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    # Listen on all interfaces
    app.run(host='0.0.0.0', port=5000)
