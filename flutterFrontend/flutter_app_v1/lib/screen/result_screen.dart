import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';
import 'package:open_file/open_file.dart';

class ResultPage extends StatelessWidget {
  Future<void> _downloadFile(String filename, BuildContext context) async {
    try {
      // 1. Permintaan permission
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Izin penyimpanan ditolak');
      }

      // 2. URL encoding file hasil = uploadscreen dynamic
      String encodedFilename = Uri.encodeComponent(filename);
      var response = await http.get(
        Uri.parse('http://192.168.240.253:5000/download/$encodedFilename'),
        headers: {'Connection': 'keep-alive'},
      );

      // 3.  Cek kondisi respon
      if (response.statusCode == 200) {
        Directory? dir = await getDownloadsDirectory();
        String filePath = '${dir!.path}/$filename';

        // 4. Simpan file
        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // 5. Buka file explorer
        await OpenFile.open(filePath);
      } else {
        throw Exception('Gagal download: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return Scaffold(
      // AppBar
      appBar: AppBar(
        title: Text('Hasil Kompresi'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF6A11CB),
                Color(0xFF2575FC),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      // Background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF6A11CB).withOpacity(0.1),
              Color(0xFF2575FC).withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResultItem(
                  'Ukuran File Asli', _formatSize(args['original_size'])),
              _buildResultItem('Ukuran Setelah Kompresi',
                  _formatSize(args['compressed_size'])),
              _buildResultItem('Rasio Kompresi',
                  '${args['compression_ratio'].toStringAsFixed(2)}%'),
              _buildResultItem('Waktu Kompresi',
                  '${args['compress_time'].toStringAsFixed(2)} detik'),
              _buildResultItem('Waktu Dekompresi',
                  '${args['decompress_time'].toStringAsFixed(2)} detik'),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _downloadFile(args['compressed_file'], context),
                  icon: Icon(Icons.download),
                  label: const Text('Download File Terkompresi'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    backgroundColor: Colors.transparent,
                    textStyle: const TextStyle(fontSize: 16),
                    shadowColor: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }
}
