import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:get/get.dart';
import 'package:file_saver/file_saver.dart';
import 'package:archive/archive.dart';

class UmlOutputCard extends StatefulWidget {
  final String umlCode;

  const UmlOutputCard({super.key, required this.umlCode});

  @override
  State<UmlOutputCard> createState() => _UmlOutputCardState();
}

class _UmlOutputCardState extends State<UmlOutputCard> {
  bool isCodeView = false;
  bool isLoadingImage = true;
  late final String encodedPngUrl;

  @override
  void initState() {
    super.initState();
    encodedPngUrl = _generatePngUrl(widget.umlCode);
  }

  String _generatePngUrl(String umlCode) {
    final encoded = _encodePlantUml(umlCode);
    return "https://www.plantuml.com/plantuml/png/~1$encoded";
  }

  String _encodePlantUml(String umlCode) {
    final bytes = utf8.encode(umlCode);
    final compressed = ZLibEncoder().encode(bytes)!;

    const encodeTable = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_';
    String encode6bit(int b) => encodeTable[b & 0x3F];
    String append3bytes(int b1, int b2, int b3) {
      final c1 = b1 >> 2;
      final c2 = ((b1 & 0x3) << 4) | (b2 >> 4);
      final c3 = ((b2 & 0xF) << 2) | (b3 >> 6);
      final c4 = b3 & 0x3F;
      return encode6bit(c1) + encode6bit(c2) + encode6bit(c3) + encode6bit(c4);
    }

    final sb = StringBuffer();
    for (var i = 0; i < compressed.length; i += 3) {
      final b1 = compressed[i];
      final b2 = (i + 1 < compressed.length) ? compressed[i + 1] : 0;
      final b3 = (i + 2 < compressed.length) ? compressed[i + 2] : 0;
      sb.write(append3bytes(b1, b2, b3));
    }

    return sb.toString();
  }

  Future<void> _copyCodeToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.umlCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copied to clipboard')),
    );
  }



  Future<void> _downloadAndSaveImage() async {
    final response = await http.get(Uri.parse(encodedPngUrl));
    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      await ImageGallerySaverPlus.saveImage(
        bytes,
        name: "uml_diagram_${DateTime.now().millisecondsSinceEpoch}",
      );
      Get.snackbar("✅ Saved", "Image saved to gallery", backgroundColor: Colors.green, colorText: Colors.white);
    } else {
      Get.snackbar("❌ Error", "Failed to download image", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 4,
      color: Color(0xFFf3ccff),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isCodeView ? "UML Code View" : "Zoomable Diagram View",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(isCodeView ? Icons.image : Icons.code),
                    onPressed: () => setState(() => isCodeView = !isCodeView),
                  ),
                ],
              ),
            ),

            isCodeView
                ? Container(
              width: double.infinity,

              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(widget.umlCode),
            )
                :SizedBox(
              height: MediaQuery.of(context).size.height * 0.5, // 🟢 Increase this value for taller diagrams
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: PhotoView(
                  imageProvider: NetworkImage(encodedPngUrl),
                  loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator()),
                  backgroundDecoration: const BoxDecoration(color: Colors.transparent),
                  minScale: PhotoViewComputedScale.covered,
                  maxScale: PhotoViewComputedScale.covered * 3,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.0,vertical: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text("Copy Code"),
                    onPressed: _copyCodeToClipboard,
                  ),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text("Save Image"),
                    onPressed: _downloadAndSaveImage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
