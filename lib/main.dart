import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';

void main() {
  runApp(const DicomConverterApp());
}

class DicomConverterApp extends StatelessWidget {
  const DicomConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DICOM to JPG Converter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.cyanAccent,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyanAccent,
          brightness: Brightness.dark,
          surface: const Color(0xFF1E293B), // Slate 800
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFF334155), // Slate 700
          labelStyle: const TextStyle(color: Colors.cyanAccent),
        ),
      ),
      home: const ConverterHomePage(),
    );
  }
}

class ConverterHomePage extends StatefulWidget {
  const ConverterHomePage({super.key});

  @override
  State<ConverterHomePage> createState() => _ConverterHomePageState();
}

class _ConverterHomePageState extends State<ConverterHomePage> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  String _statusMessage = 'Ready';
  bool _isConverting = false;
  List<String> _selectedFiles = []; // Tracks specific files if picked
  String _outputFormat = 'jpg'; // Default format

  @override
  void initState() {
    super.initState();
    _initPaths();
  }

  void _initPaths() {
    if (!kIsWeb) {
      try {
        _inputController.text = '${Directory.current.path}/input_img';
        _outputController.text = '${Directory.current.path}/output_img';
      } catch (e) {
        // Fallback or handle error
      }
    }
  }

  Future<void> _selectFolder(TextEditingController controller) async {
    if (kIsWeb) return;
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        controller.text = selectedDirectory;
        if (controller == _inputController) {
          _selectedFiles = []; // Clear file selection if a folder is picked
        }
      });
    }
  }

  Future<void> _selectFiles() async {
    if (kIsWeb) return;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dcm', 'DCM', 'dicom', 'DICOM'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _selectedFiles = result.paths.whereType<String>().toList();
        _inputController.text = '${_selectedFiles.length} files selected';
      });
    }
  }

  Future<void> _convert() async {
    if (kIsWeb) {
      setState(
        () => _statusMessage = 'Local conversion is not supported on Web.',
      );
      return;
    }

    if (_inputController.text.isEmpty || _outputController.text.isEmpty) {
      setState(() => _statusMessage = 'Select paths first.');
      return;
    }

    setState(() {
      _isConverting = true;
      _statusMessage = 'Processing...';
    });

    try {
      final pythonExecutable = Platform.isWindows ? 'python' : 'python3';

      List<String> args = [
        'convert_dcm_to_jpg.py',
        '--output',
        _outputController.text,
        '--format',
        _outputFormat,
      ];

      if (_selectedFiles.isNotEmpty) {
        args.add('--files');
        args.addAll(_selectedFiles);
      } else {
        args.add('--input');
        args.add(_inputController.text);
      }

      final result = await Process.run(
        pythonExecutable,
        args,
        runInShell: true,
      );

      setState(() {
        if (result.exitCode == 0) {
          _statusMessage = 'Success!\n\n${result.stdout}';
        } else {
          _statusMessage = 'Failed.\n\n${result.stderr}';
        }
      });
    } catch (e) {
      setState(() => _statusMessage = 'Error: $e');
    } finally {
      setState(() => _isConverting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 40.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildControls()),
                      const SizedBox(width: 40),
                      Expanded(flex: 3, child: _buildStatusArea()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(
          Icons.settings_system_daydream_outlined,
          size: 60,
          color: Colors.cyanAccent,
        ),
        const SizedBox(height: 12),
        const Text(
          'DICOM Vision',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        const Text(
          'Desktop Power Mode',
          style: TextStyle(
            fontSize: 14,
            color: Colors.cyanAccent,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputSelector(),
          const SizedBox(height: 20),
          _buildPathSelector(
            label: 'Output Folder',
            controller: _outputController,
            icon: Icons.drive_file_move_outline,
            onPressed: () => _selectFolder(_outputController),
          ),
          const SizedBox(height: 24),
          _buildFormatSelector(),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _isConverting ? null : _convert,
            child: _isConverting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'START CONVERSION',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSelector() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _inputController,
            decoration: const InputDecoration(
              labelText: 'Input (Folder or Files)',
              prefixIcon: Icon(Icons.folder_open, color: Colors.cyanAccent),
            ),
            readOnly: true,
          ),
        ),
        const SizedBox(width: 8),
        _buildSmallButton(
          Icons.folder,
          () => _selectFolder(_inputController),
          'Pick Folder',
        ),
        const SizedBox(width: 8),
        _buildSmallButton(Icons.file_present, _selectFiles, 'Pick Files'),
      ],
    );
  }

  Widget _buildSmallButton(
    IconData icon,
    VoidCallback onPressed,
    String tooltip,
  ) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.cyanAccent, size: 20),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFF334155),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Output Format',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _buildFormatBtn(
                'JPG',
                _outputFormat == 'jpg',
                () => setState(() => _outputFormat = 'jpg'),
              ),
              _buildFormatBtn(
                'PNG',
                _outputFormat == 'png',
                () => setState(() => _outputFormat = 'png'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormatBtn(String label, bool active, VoidCallback tap) {
    return Expanded(
      child: GestureDetector(
        onTap: tap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.cyanAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: active ? Colors.black : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'CONSOLE LOGS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF020617),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: SingleChildScrollView(
              child: Text(
                _statusMessage,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Colors.greenAccent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPathSelector({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, color: Colors.cyanAccent),
            ),
            readOnly: true,
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: onPressed,
          icon: const Icon(Icons.more_horiz, color: Colors.cyanAccent),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF334155),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
