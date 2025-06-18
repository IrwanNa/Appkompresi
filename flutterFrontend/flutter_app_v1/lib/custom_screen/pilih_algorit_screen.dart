


// import 'package:flutter/material.dart';

// class UploadPage extends StatefulWidget {
//   @override
//   _UploadPageState createState() => _UploadPageState();
// }

// class _UploadPageState extends State<UploadPage> {
//   String? _filePath;
//   String? _fileName;
//   int? _fileSize;
//   String _selectedMethod = 'deflate';
//   bool _isLoading = false;

//   Future<void> _pickFile() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['docx', 'pdf', 'pptx', 'txt'],
//     );

//     if (result != null) {
//       if (result.files.single.size > 50 * 1024 * 1024) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Ukuran file melebihi 50MB')),
//         );
//         return;
//       }

//       setState(() {
//         _filePath = result.files.single.path!;
//         _fileName = result.files.single.name;
//         _fileSize = result.files.single.size;
//       });
//     }
//   }

//   Future<void> _compressFile() async {
//     if (_filePath == null) return;

//     setState(() => _isLoading = true);

//     var request = http.MultipartRequest(
//       'POST',
//       Uri.parse('http://<your-server-ip>:5000/compress'),
//     );
//     request.files.add(await http.MultipartFile.fromPath('file', _filePath!));
//     request.fields['method'] = _selectedMethod;

//     try {
//       var response = await request.send();
//       if (response.statusCode == 200) {
//         var responseData = await response.stream.bytesToString();
//         Navigator.pushNamed(
//           context,
//           '/result',
//           arguments: json.decode(responseData),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: ${response.reasonPhrase}')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Kompresi File')),
//       body: Padding(
//         padding: EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             ElevatedButton(
//               onPressed: _pickFile,
//               child: Text('Pilih File'),
//             ),
//             SizedBox(height: 20),
//             if (_fileName != null) ...[
//               Text('File terpilih: $_fileName'),
//               Text('Ukuran: ${_formatSize(_fileSize!)}'),
//               SizedBox(height: 20),
//             ],
//             RadioListTile<String>(
//               title: Text('Deflate Compression'),
//               value: 'deflate',
//               groupValue: _selectedMethod,
//               onChanged: (value) => setState(() => _selectedMethod = value!),
//             ),
//             RadioListTile<String>(
//               title: Text('Lempel Ziv Welch (LZW)'),
//               value: 'lzw',
//               groupValue: _selectedMethod,
//               onChanged: (value) => setState(() => _selectedMethod = value!),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _isLoading ? null : _compressFile,
//               child: _isLoading
//                   ? CircularProgressIndicator(color: Colors.white)
//                   : Text('Kompres Sekarang'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatSize(int bytes) {
//     if (bytes <= 0) return '0 B';
//     const suffixes = ['B', 'KB', 'MB', 'GB'];
//     var i = (log(bytes) / log(1024)).floor();
//     return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
//   }
// }