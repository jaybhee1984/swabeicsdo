import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:swabeicsdo/auth_provider.dart' as custom_auth;
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';

class ViewPDSScreen extends StatefulWidget {
  const ViewPDSScreen({super.key});

  @override
  State<ViewPDSScreen> createState() => _ViewPDSScreenState();
}

class _ViewPDSScreenState extends State<ViewPDSScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<String> pdfUrls = [];
  List<Widget> pdfViews = [];
  bool isLoading = true;
  bool hasError = false;
  String fullName = '';
  String employeeNumber = '';
  String? excelUrl;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _downloadedFilePath;

  @override
  void initState() {
    super.initState();
    _loadPDS();
  }

  Future<void> _loadPDS() async {
    final authProvider = Provider.of<custom_auth.AuthProvider>(
      context,
      listen: false,
    );
    final empNo = authProvider.employeeNumber;
    debugPrint('Employee Number: $empNo');

    if (empNo.isEmpty) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      return;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('pds_files')
          .where('employee_number', isEqualTo: empNo) // ✅ Correct field name
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        pdfUrls = List<String>.from(data['pdfPaths'] ?? []);
        fullName = data['full_name'] ?? '';
        employeeNumber = data['employee_number'] ?? '';
        excelUrl = data['excelUrl'];

        debugPrint('Fetched PDF URLs: $pdfUrls');
        debugPrint('Excel URL: $excelUrl');

        pdfViews = pdfUrls
            .map(
              (url) => Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InteractiveViewer(
                    panEnabled: true,
                    scaleEnabled: true,
                    minScale: 1.0,
                    maxScale: 5.0,
                    child: SfPdfViewer.network(
                      url,
                      canShowScrollHead: true,
                      canShowScrollStatus: true,
                      enableDoubleTapZooming: true,
                      onDocumentLoadFailed: (details) {
                        debugPrint('PDF Load Failed: ${details.error}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to load PDF: ${details.error}',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            )
            .toList();

        if (pdfViews.isNotEmpty) {
          _tabController = TabController(length: pdfViews.length, vsync: this);
        } else {
          hasError = true;
        }
      } else {
        hasError = true;
      }
    } catch (e) {
      debugPrint('Error loading PDS: $e');
      hasError = true;
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _downloadExcelFile() async {
    if (excelUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excel file not available.')),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final dio = Dio();
      final downloadsDir = Directory('/storage/emulated/0/Download');
      final fileName = excelUrl!.split('/').last.split('?').first;
      final savePath = '${downloadsDir.path}/$fileName';

      await dio.download(
        excelUrl!,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      setState(() {
        _isDownloading = false;
        _downloadedFilePath = savePath;
      });

      _showSuccessDialog(fileName);
    } catch (e) {
      debugPrint('Download error: $e');
      setState(() {
        _isDownloading = false;
      });
    }
  }

  void _showSuccessDialog(String fileName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 16),
                const Text(
                  'Download Complete!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '$fileName saved in Downloads folder.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_downloadedFilePath != null) {
                      OpenFilex.open(_downloadedFilePath!);
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 48),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: Text(fullName.isNotEmpty ? fullName : 'View PDS'),
                ),
                if (_tabController != null)
                  TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: List.generate(
                      pdfViews.length,
                      (index) => Tab(text: 'C${index + 1}'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Color.fromARGB(255, 3, 142, 135)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : hasError || pdfViews.isEmpty
            ? const Center(child: Text('No PDS files found or failed to load.'))
            : TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: pdfViews,
              ),
      ),
      floatingActionButton: Container(
        width: 200,
        height: 55,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.green, Colors.white],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: _isDownloading
            ? ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    LinearProgressIndicator(
                      value: _downloadProgress,
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green,
                      ),
                      minHeight: 55,
                    ),
                    Text(
                      'Downloading ${(_downloadProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            : FloatingActionButton.extended(
                onPressed: _downloadExcelFile,
                backgroundColor: Colors.transparent,
                elevation: 0,
                label: const Text(
                  'Download PDS',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
