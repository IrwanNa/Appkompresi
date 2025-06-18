import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class UploadPage extends StatefulWidget {
  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  String? _filePath;
  String? _fileName;
  int? _fileSize;
  String? _selectedMethod;
  bool _isLoading = false;

  final snackBarColor = const Color(0xFF2575FC);

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: snackBarColor,
      ),
    );
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx', 'pdf', 'pptx', 'txt'],
    );

    if (result != null) {
      final sizeInBytes = result.files.single.size;
      final file = result.files.single;
      final extension = file.extension?.toLowerCase();

      if (extension == null ||
          !['docx', 'pdf', 'pptx', 'txt'].contains(extension)) {
        _showSnackBar(
            'File uji yang diinput tidak sesuai dengan format yang diujikan');
        return;
      }

      if (sizeInBytes > 50 * 1024 * 1024) {
        _showSnackBar('Ukuran file uji melebihi 50MB');
        return;
      }

      setState(() {
        _filePath = result.files.single.path!;
        _fileName = result.files.single.name;
        _fileSize = sizeInBytes;
      });
    } else {
      _showSnackBar('Tidak ada file uji yang dipilih');
    }
  }

  Future<void> _compressFile() async {
    if (_filePath == null) {
      _showSnackBar('Silakan pilih file uji terlebih dahulu');
      return;
    }

    if (_selectedMethod == null || _selectedMethod!.isEmpty) {
      _showSnackBar('Silakan pilih metode kompresi terlebih dahulu');
      return;
    }

    setState(() => _isLoading = true);
    // URL upload ke server = resultscreen dynamic
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.240.253:5000/compress'),
    );

    request.files.add(await http.MultipartFile.fromPath('file', _filePath!));
    request.fields['method'] = _selectedMethod!;

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        Navigator.pushNamed(
          context,
          '/result',
          arguments: json.decode(responseData),
        );
      } else {
        _showSnackBar('Error: ${response.reasonPhrase}');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kompresi File'),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _pickFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: snackBarColor,
                ),
                child: Text('Pilih File'),
              ),
              SizedBox(height: 20),
              if (_fileName != null) ...[
                Text(
                  'File terpilih: $_fileName',
                  style: TextStyle(color: Colors.black87),
                ),
                Text(
                  'Ukuran: ${_formatSize(_fileSize!)}',
                  style: TextStyle(color: Colors.black54),
                ),
                SizedBox(height: 20),
              ],
              RadioListTile<String>(
                title: const Text('Deflate Compression'),
                value: 'deflate',
                groupValue: _selectedMethod,
                onChanged: (value) => setState(() => _selectedMethod = value!),
              ),
              RadioListTile<String>(
                title: const Text('Lempel Ziv Welch (LZW)'),
                value: 'lzw',
                groupValue: _selectedMethod,
                onChanged: (value) => setState(() => _selectedMethod = value!),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _compressFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: snackBarColor,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Kompres Sekarang'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
