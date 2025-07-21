import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class InputService {
  static Future<String> extractTextFromImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final result = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();
    return result.text;
  }

  static Future<String> extractTextFromPdf(File file) async {
    final bytes = await file.readAsBytes();
    final doc = PdfDocument(inputBytes: bytes);
    final text = PdfTextExtractor(doc).extractText();
    doc.dispose();
    return text;
  }
}
