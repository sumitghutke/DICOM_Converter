# DICOM Vision 🏥

[![License: Proprietary](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.8%2B-blue.svg?style=flat&logo=python&logoColor=white)](https://www.python.org/)

A premium, cross-platform **DICOM to Image Converter** (JPG/PNG) built with **Flutter** for the frontend and **Python** for the processing engine. It offers high-performance batch processing for desktop users and a scalable web interface for remote access.

---

## ✨ Features

- 🎨 **Premium UI/UX**: Modern slate-themed interface with smooth animations and glassmorphism.
- 🚀 **Dual Processing Modes**:
  - **Local Power Mode**: Leverages local Python installation for rapid batch processing.
  - **Cloud/Remote Mode**: Uses a Flask API for server-side conversion (ideal for web/mobile).
- ⚙️ **Intelligent Windowing**: Automatic implementation of DICOM W/L tags for optimal visualization.
- 📁 **Batch Processing**: Convert entire directories or selected files with a single click.
- 🖼️ **Format Support**: Export to high-quality `.jpg` or lossless `.png`.
- 🖥️ **Cross-Platform**: Native support for Linux, Windows, macOS, and Web.

---

## 🛠️ Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Flask (Python)
- **Processing**: pydicom, OpenCV, NumPy
- **Communication**: REST API (Remote) / CLI (Local)

---

## 🚀 Getting Started

### 1. Prerequisites

#### Python Environment
Ensure you have Python 3.8+ installed. Install the dependencies:
```bash
pip install -r requirements.txt
```

#### Linux Build Tools (Native Only)
On Ubuntu/Debian, install the required build dependencies:
```bash
sudo apt update
sudo apt install build-essential clang cmake ninja-build pkg-config libgtk-3-dev
```

### 2. Running the Application

#### **Mode A: Desktop (Linux/Windows/macOS)**
Run directly as a native application:
```bash
flutter run -d linux # or windows/macos
```

#### **Mode B: Web Interface**
1. Start the processing server:
   ```bash
   python server.py
   ```
2. Run the flutter web client:
   ```bash
   flutter run -d chrome
   ```

---

## 📂 Project Structure

```text
├── lib/                   # Flutter application source
├── convert_dcm_to_jpg.py  # Standalone CLI processing script
├── server.py              # Flask API for remote conversion
├── requirements.txt       # Python dependencies
├── pubspec.yaml           # Flutter/Dart dependencies
└── .gitignore             # Optimized exclusion rules
```

---

## 🤝 Contributing

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📜 License

This project is licensed under a **Proprietary License**. 

- **Personal/Educational Use**: Free.
- **Commercial Use & Replication**: Requires a **paid commercial license**.

If you intend to replicate this software for commercial purposes, sell it, or use it within a business environment, you **must contact the author** to arrange for licensing and payment. See the [LICENSE](LICENSE) file for full details.

---

**Developed for high-performance medical imaging workflows.**
