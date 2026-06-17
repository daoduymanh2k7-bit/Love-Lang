import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../models/album_model.dart';
import '../models/photo_model.dart';

class AlbumRemoteDataSource {
  final FirebaseFirestore _firestore;

  AlbumRemoteDataSource(this._firestore);

  Stream<List<AlbumModel>> watchAlbums(String coupleId) {
    return _firestore
        .collection(FirestorePaths.albums)
        .where('coupleId', isEqualTo: coupleId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AlbumModel.fromFirestore(doc, null))
          .toList();
    });
  }

  Stream<List<PhotoModel>> watchPhotos(String albumId) {
    return _firestore
        .collection(FirestorePaths.albums)
        .doc(albumId)
        .collection('photos')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PhotoModel.fromFirestore(doc, null))
          .toList();
    });
  }

  Future<String> createAlbum(AlbumModel album) async {
    final docRef = _firestore.collection(FirestorePaths.albums).doc(album.id);
    await docRef.set(album.toFirestore());
    return docRef.id;
  }

  Future<void> uploadPhotos(
    String albumId,
    String coupleId,
    String uploaderId,
    List<String> localFilePaths,
  ) async {
    final batch = _firestore.batch();
    final photosRef = _firestore
        .collection(FirestorePaths.albums)
        .doc(albumId)
        .collection('photos');

    final cloudinary = CloudinaryPublic('dq3bk50q9', 'love_lang_bucket', cache: false);

    final uploadTasks = localFilePaths.map((filePath) async {
      final file = File(filePath);
      if (!await file.exists()) return;

      try {
        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            file.path,
            resourceType: CloudinaryResourceType.Image,
          ),
        );
        final secureUrl = response.secureUrl;

        final photoId = photosRef.doc().id;
        final photoModel = PhotoModel(
          id: photoId,
          albumId: albumId,
          uploadedById: uploaderId,
          url: secureUrl,
          description: '',
          createdAt: DateTime.now(),
        );

        batch.set(photosRef.doc(photoId), photoModel.toFirestore());
      } catch (e) {
        debugPrint('Cloudinary upload error: $e');
      }
    }).toList();

    await Future.wait(uploadTasks);
    await batch.commit();
  }

  // ── Mới thêm ──────────────────────────────────────────────────────────────

  Future<void> updateAlbum(
    String albumId, {
    String? title,
    String? description,
    String? coverUrl,
  }) async {
    final Map<String, dynamic> data = {};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (coverUrl != null) data['coverUrl'] = coverUrl;
    if (data.isEmpty) return;

    await _firestore
        .collection(FirestorePaths.albums)
        .doc(albumId)
        .update(data);
  }

  Future<void> deleteAlbum(String albumId) async {
    // Xóa toàn bộ ảnh trong sub-collection trước
    final photosSnapshot = await _firestore
        .collection(FirestorePaths.albums)
        .doc(albumId)
        .collection('photos')
        .get();

    final batch = _firestore.batch();
    for (final doc in photosSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection(FirestorePaths.albums).doc(albumId));
    await batch.commit();
  }

  Future<void> deletePhoto(String albumId, String photoId) async {
    await _firestore
        .collection(FirestorePaths.albums)
        .doc(albumId)
        .collection('photos')
        .doc(photoId)
        .delete();
  }

  Future<void> deletePhotos(String albumId, List<String> photoIds) async {
    if (photoIds.isEmpty) return;
    final batch = _firestore.batch();
    for (final photoId in photoIds) {
      batch.delete(
        _firestore
            .collection(FirestorePaths.albums)
            .doc(albumId)
            .collection('photos')
            .doc(photoId),
      );
    }
    await batch.commit();
  }
}
