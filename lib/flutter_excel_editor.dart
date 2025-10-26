import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ExcelEditorScreen extends StatefulWidget {
  final String excelPathInStorage;
  const ExcelEditorScreen({super.key, required this.excelPathInStorage});

  @override
  State<ExcelEditorScreen> createState() => _ExcelEditorScreenState();
}

class _ExcelEditorScreenState extends State<ExcelEditorScreen> {
  bool _isDownloading = false;
  bool _isUploading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _downloadExcelFile(); // Automatically trigger download
  }

  Future<String> _getDownloadsPath() async {
    return '/storage/emulated/0/Download';
  }

  Future<void> _downloadExcelFile() async {
    setState(() {
      _isDownloading = true;
      _statusMessage = 'Downloading Excel file...';
    });

    try {
      final downloadsPath = await _getDownloadsPath();
      final fileName = widget.excelPathInStorage.split('/').last;
      final localPath = '$downloadsPath/$fileName';
      final file = File(localPath);
      final ref = FirebaseStorage.instance.ref(widget.excelPathInStorage);
      await ref.writeToFile(file);

      if (!mounted) return;
      setState(() => _isDownloading = false);

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Excel Downloaded'),
          content: Text(
            'The file has been saved to your Downloads folder:\n\n$localPath\n\n'
            '📌 If Excel asks where to save the file, please choose the Downloads folder and overwrite the existing file.\n\n'
            'After editing and closing Excel, the updated file will be uploaded automatically.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                //await OpenFile.open(localPath);
                await _uploadEditedExcel(File(localPath));
              },
              child: const Text('Open Excel'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to download Excel file')),
      );
    }
  }

  Future<void> _uploadEditedExcel(File file) async {
    setState(() {
      _isUploading = true;
      _statusMessage = 'Uploading updated Excel file...';
    });

    try {
      final ref = FirebaseStorage.instance.ref(widget.excelPathInStorage);
      await ref.putFile(file);

      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _statusMessage = null;
      });

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('✅ Upload Complete'),
          content: const Text(
            'Your updated PDS has been uploaded successfully.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _statusMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to upload updated Excel')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit PDS')),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Background Logo
            Positioned.fill(
              child: Opacity(
                opacity: 0.08,
                child: Center(
                  child: Image.asset(
                    'assets/logo.png', // Ensure this path is correct
                    width: 400,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Foreground Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isDownloading || _isUploading)
                          Column(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 20),
                              Text(
                                _statusMessage ?? '',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        if (!_isDownloading && !_isUploading)
                          const Text(
                            'Preparing your Excel file...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ),
                // Permanent Note at Bottom
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '📌 Note: The file will be saved in your Downloads folder.\n'
                    'If Excel asks where to save, choose Downloads and overwrite the file.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
