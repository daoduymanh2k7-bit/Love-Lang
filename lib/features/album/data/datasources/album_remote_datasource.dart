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

  Future<void> uploadPhotos(String albumId, String coupleId, String uploaderId,
      List<String> localFilePaths) async {
    final batch = _firestore.batch();
    final photosRef = _firestore
        .collection(FirestorePaths.albums)
        .doc(albumId)
        .collection('photos');

    // Create a Cloudinary instance (unsigned preset)
    final cloudinary = CloudinaryPublic('dq3bk50q9', 'love_lang_bucket', cache: false);
    // Upload each file to Cloudinary and collect the secure URL
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

        // Prepare Firestore data for the photo
        final photoId = photosRef.doc().id;
        final photoModel = PhotoModel(
          id: photoId,
          albumId: albumId,
          uploadedById: uploaderId,
          url: secureUrl, // Store Cloudinary secure URL
          description: '',
          createdAt: DateTime.now(),
        );

        batch.set(photosRef.doc(photoId), photoModel.toFirestore());
      } catch (e) {
        debugPrint('Cloudinary upload error: $e');
        // Optionally you could rethrow or handle differently
      }
    }).toList();

    // Chờ tất cả file upload xong
    await Future.wait(uploadTasks);

    // Lưu batch vào Firestore
    await batch.commit();
  }
}
