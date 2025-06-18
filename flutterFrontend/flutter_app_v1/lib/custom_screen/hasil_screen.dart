

// import 'package:flutter/material.dart';


// class ResultPage extends StatelessWidget {
//   Future<void> _downloadFile(String filename) async {
//     var status = await Permission.storage.request();
//     if (!status.isGranted) return;

//     var response = await http.get(
//       Uri.parse('http://<your-server-ip>:5000/download/$filename'),
//     );

//     var dir = await getDownloadsDirectory();
//     var filePath = '${dir!.path}/$filename';
//     await File(filePath).writeAsBytes(response.bodyBytes);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final args =
//         ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

//     return Scaffold(
//       appBar: AppBar(title: Text('Hasil Kompresi')),
//       body: Padding(
//         padding: EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildResultItem(
//                 'Ukuran File Asli', _formatSize(args['original_size'])),
//             _buildResultItem('Ukuran Setelah Kompresi',
//                 _formatSize(args['compressed_size'])),
//             _buildResultItem('Rasio Kompresi',
//                 '${args['compression_ratio'].toStringAsFixed(2)}%'),
//             _buildResultItem('Waktu Kompresi',
//                 '${args['compress_time'].toStringAsFixed(2)} detik'),
//             _buildResultItem('Waktu Dekompresi',
//                 '${args['decompress_time'].toStringAsFixed(2)} detik'),
//             SizedBox(height: 30),
//             Center(
//               child: ElevatedButton.icon(
//                 onPressed: () => _downloadFile(args['compressed_file']),
//                 icon: Icon(Icons.download),
//                 label: Text('Download File Terkompresi'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildResultItem(String title, String value) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
//           Text(value),
//         ],
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