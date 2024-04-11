import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Reader Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PdfReaderPage(),
    );
  }
}

class PdfReaderPage extends StatefulWidget {
  @override
  _PdfReaderPageState createState() => _PdfReaderPageState();
}

class _PdfReaderPageState extends State<PdfReaderPage> {
  String? _filePath;
  bool _downloading = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _checkPdfFile();
  }

  Future<void> _checkPdfFile() async {
    final externalDir = await getApplicationDocumentsDirectory();
    final filePath = '${externalDir.path}/encrypted_pdf.pdf';
    final file = File(filePath);
    if (file.existsSync()) {
      setState(() {
        _filePath = filePath;
      });
    }
  }

  Future<void> _fetchAndSavePdf() async {
    setState(() {
      _downloading = true;
    });

    try {
      var headers = {
        'Content-Type': 'application/json',
      };
      var data = json.encode({
        "userId": 8,
        "jwtToken":
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjgsImFjY291bnQiOiJ0ZXN0MiIsImlhdCI6MTcxMjU4NDk1NS45OTksImV4cCI6MTcxMjU4NTAxNS45OTl9.hazdBpxMlnFgwOVfoebN-XZw7x42Yz_q5ppsPEM3FK8",
        "refreshToken": "8223b02650864eeaade8ed9dd1dc3ff4",
        "productId": 55
      });
      var dio = Dio();

      // 获取外部存储路径
      Directory? externalDir = await getApplicationDocumentsDirectory();
      if (externalDir != null) {
        final String externalPath = externalDir.path;
        final tempFilePath = '$externalPath/temp_encrypted_pdf.pdf';
        // 下載時先存成暫存檔，避免下載到一半中斷變成損壞檔，要開啟閱讀時失敗
        // 必須等到下載100%完後，再將此暫存檔重新命名為 之後永久的檔名

        // 使用Dio的download方法下载文件到临时文件
        await dio.download(
          'https://ebookapi.shingonzo.com/book/downloadBook',
          tempFilePath,
          options: Options(
            headers: headers,
          ),
          onReceiveProgress: (received, total) {
            if (total != -1) {
              setState(() {
                _progress = received / total;
              });
              print((_progress * 100).toStringAsFixed(0) + "%");
            }
          },
          data: data,
        );

        // 下载完成后将临时文件重命名为原始文件
        final filePath = '${externalDir.path}/encrypted_pdf.pdf';
        await File(tempFilePath).rename(filePath);

        setState(() {
          _filePath = filePath;
          _downloading = false;
        });
      } else {
        print("External storage directory is null.");
        setState(() {
          _downloading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _downloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Reader Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_downloading)
              Column(
                children: [
                  LinearProgressIndicator(value: _progress),
                  SizedBox(height: 10),
                  Text('${(_progress * 100).toStringAsFixed(0)}%'),
                ],
              ),
            if (_filePath == null && !_downloading)
              ElevatedButton(
                onPressed: _fetchAndSavePdf,
                child: Text('下载PDF Download'),
              ),
            if (_filePath != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfViewScreen(filePath: _filePath!),
                    ),
                  );
                },
                child: Text('开始阅读 Start reading'),
              ),
          ],
        ),
      ),
    );
  }
}

class PdfViewScreen extends StatelessWidget {
  final String filePath;

  const PdfViewScreen({Key? key, required this.filePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Viewer'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: PDFView(
                  filePath: filePath,
                  password: 'f47c92ee56d1daabcbd970c6971ffa13',
                  enableSwipe: true,
                  swipeHorizontal: true,
                  fitPolicy: FitPolicy.WIDTH,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('关闭'),
            ),
          ],
        ),
      ),
    );
  }
}
