import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const ImageCompressor(),
    );
  }
}

class ImageCompressor extends StatefulWidget {
  const ImageCompressor({super.key});

  @override
  State<ImageCompressor> createState() => _ImageCompressorState();
}

class _ImageCompressorState extends State<ImageCompressor> {
  Uint8List? originalImage;
  Uint8List? compressedImage;
  String? originalSize = '';
  String? compressedSize = '';
  double compressionQuality = 40;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image Compressor",style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: pickAndCompressImage,
              icon: const Icon(Icons.upload, color: Colors.white),
              label: const Text("Upload Image", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Text("Compression Quality: ${compressionQuality.toInt()}%"),
            Slider(
              secondaryActiveColor: Colors.teal,
              min: 10,
              max: 100,
              divisions: 9,
              value: compressionQuality,
              label: compressionQuality.toInt().toString(),
              onChanged: (value) => setState(() => compressionQuality = value),
            ),
            if (isLoading) const CircularProgressIndicator(),
            const SizedBox(height: 20),
            if (originalImage != null && compressedImage != null)
              Row(
                children: [
                  Expanded(child: buildImageCard("Original", originalImage!, originalSize!, false)),
                  const SizedBox(width: 16),
                  Expanded(child: buildImageCard("Compressed", compressedImage!, compressedSize!, true)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget buildImageCard(String title, Uint8List imageData, String sizeText, bool showSaveButton) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.black,
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4,
            child: Image.memory(imageData),
          ),
        ),
      ),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.memory(imageData, height: 150, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    '$title\nSize: $sizeText',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (showSaveButton)
                    ElevatedButton(
                      onPressed: saveCompressedImageToDownloads,
                      child: const Text("Save Photo",style: TextStyle(color: Colors.teal),),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> pickAndCompressImage() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['jpeg', 'jpg', 'png'],
    );

    if (result == null || result.files.single.path == null) return;

    final filePath = result.files.single.path!;
    final originalBytes = await File(filePath).readAsBytes();

    setState(() => isLoading = true);

    final compressedBytes = await FlutterImageCompress.compressWithList(
      originalBytes,
      quality: compressionQuality.toInt(),
    );

    setState(() {
      originalImage = originalBytes;
      compressedImage = compressedBytes;
      originalSize = formatSize(originalBytes.length);
      compressedSize = formatSize(compressedBytes.length);
      isLoading = false;
    });
  }

  Future<void> saveCompressedImageToDownloads() async {
    final downloadsDir = Directory('/storage/emulated/0/Download');
    final fileName = 'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filePath = path.join(downloadsDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(compressedImage!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved to Downloads: $filePath'),closeIconColor: Colors.teal,),
    );
  }

  String formatSize(int bytes) {
    if (bytes > 1024 * 1024) {
      return (bytes / (1024 * 1024)).toStringAsFixed(2) + " MB";
    } else {
      return (bytes / 1024).toStringAsFixed(2) + " KB";
    }
  }
}
