import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// E'lon uchun rasm yuklash
  Future<String?> uploadAnnouncementImage(File file, String fileName) async {
    try {
      final ref = _storage.ref().child('announcements/$fileName');
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      debugPrint('StorageService: Announcement image uploaded: $url');
      return url;
    } catch (e) {
      debugPrint('StorageService: Error uploading announcement image: $e');
      return null;
    }
  }

  /// UC buyurtma cheki yuklash
  Future<String?> uploadReceiptImage(File file, String orderId) async {
    try {
      final ext = file.path.split('.').last;
      final ref = _storage.ref().child('receipts/$orderId.$ext');
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      debugPrint('StorageService: Receipt image uploaded: $url');
      return url;
    } catch (e) {
      debugPrint('StorageService: Error uploading receipt image: $e');
      return null;
    }
  }

  /// Rasmni o'chirish (URL orqali)
  Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      debugPrint('StorageService: Image deleted: $url');
    } catch (e) {
      debugPrint('StorageService: Error deleting image: $e');
    }
  }
}
