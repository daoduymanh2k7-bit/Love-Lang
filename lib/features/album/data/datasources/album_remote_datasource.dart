import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../models/album_model.dart';
import '../models/photo_model.dart';

class AlbumRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  AlbumRemoteDataSource(this._firestore, this._storage);

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

  Future<void> createAlbum(AlbumModel album) async {
    final docRef = _firestore.collection(FirestorePaths.albums).doc(album.id);
    await docRef.set(album.toFirestore());
  }

  Future<void> uploadPhotos(String albumId, String coupleId, String uploaderId,
      List<String> localFilePaths) async {
    final batch = _firestore.batch();
    final photosRef = _firestore
        .collection(FirestorePaths.albums)
        .doc(albumId)
        .collection('photos');

    // Tạo danh sách Future để upload ảnh song song
    final uploadTasks = localFilePaths.map((filePath) async {
      final file = File(filePath);
      if (!await file.exists()) return;

      final fileName =
          '${DateTime.now().microsecondsSinceEpoch}_${filePath.split('/').last}';
      final storageRef =
          _storage.ref().child('couples/$coupleId/albums/$albumId/$fileName');

      // Upload file lên Firebase Storage
      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Chuẩn bị dữ liệu PhotoModel để lưu vào Firestore
      final photoId = photosRef.doc().id;
      final photoModel = PhotoModel(
        id: photoId,
        albumId: albumId,
        uploadedById: uploaderId,
        url: downloadUrl,
        description: '',
        createdAt: DateTime.now(),
      );

      batch.set(photosRef.doc(photoId), photoModel.toFirestore());
    }).toList();

    // Chờ tất cả file upload xong
    await Future.wait(uploadTasks);

    // Lưu batch vào Firestore
    await batch.commit();
  }
}
