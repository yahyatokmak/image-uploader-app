import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/uploaded_image.dart';
import 'auth_service.dart';

class FirebaseService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'uploaded_images';
  static const Uuid _uuid = Uuid();

  static String _getUserCollectionPath() {
    final userId = AuthService.currentUserId;
    if (userId == null) {
      throw Exception('User is not signed in');
    }
    return 'users/$userId/$_collectionName';
  }

  static String _getUserStoragePath(String fileName) {
    final userId = AuthService.currentUserId;
    if (userId == null) {
      throw Exception('User is not signed in');
    }
    return 'users/$userId/images/$fileName';
  }

  static Future<UploadedImage> uploadImage({
    required File imageFile,
    String? description,
  }) async {
    try {
      print('Firebase upload started');

      if (!AuthService.isAuthenticated) {
        print('User not authenticated');
        throw Exception('User authentication required');
      }

      print('User authenticated: ${AuthService.currentUserId}');

      final String fileExtension = imageFile.path.split('.').last.toLowerCase();
      final String fileName =
          '${_uuid.v4()}.${fileExtension.isNotEmpty && ['jpg', 'jpeg', 'png', 'heic'].contains(fileExtension) ? fileExtension : 'jpg'}';
      final String filePath = _getUserStoragePath(fileName);

      final int fileSize = await imageFile.length();

      final Reference ref = _storage.ref().child(filePath);
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/${fileExtension == 'jpg' ? 'jpeg' : fileExtension}',
        customMetadata: {
          'uploaded_by': AuthService.currentUserId!,
          'upload_timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final UploadTask uploadTask = ref.putFile(imageFile, metadata);

      print('Starting Firebase Storage upload...');
      final TaskSnapshot snapshot = await uploadTask;
      print('Storage upload completed');

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print('Download URL obtained: $downloadUrl');

      final UploadedImage uploadedImage = UploadedImage(
        id: '',
        downloadUrl: downloadUrl,
        fileName: fileName,
        uploadedAt: DateTime.now(),
        fileSize: fileSize,
        description: description,
      );

      print('Saving to Firestore...');
      final DocumentReference docRef = await _firestore
          .collection(_getUserCollectionPath())
          .add(uploadedImage.toFirestore());

      print('Firestore save completed. Document ID: ${docRef.id}');

      return uploadedImage.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Image upload failed: ${e.toString()}');
    }
  }

  static Future<List<UploadedImage>> getAllUploadedImages() async {
    try {
      if (!AuthService.isAuthenticated) {
        throw Exception('User authentication required');
      }

      final QuerySnapshot querySnapshot = await _firestore
          .collection(_getUserCollectionPath())
          .orderBy('uploadedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UploadedImage.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to retrieve images: ${e.toString()}');
    }
  }

  static Future<UploadedImage?> getUploadedImageById(String id) async {
    try {
      if (!AuthService.isAuthenticated) {
        throw Exception('User authentication required');
      }

      final DocumentSnapshot doc = await _firestore
          .collection(_getUserCollectionPath())
          .doc(id)
          .get();

      if (doc.exists) {
        return UploadedImage.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to retrieve image: ${e.toString()}');
    }
  }

  static Future<void> deleteUploadedImage(UploadedImage image) async {
    try {
      if (!AuthService.isAuthenticated) {
        throw Exception('User authentication required');
      }

      final String filePath = _getUserStoragePath(image.fileName);
      final Reference ref = _storage.ref().child(filePath);
      await ref.delete();

      await _firestore
          .collection(_getUserCollectionPath())
          .doc(image.id)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete image: ${e.toString()}');
    }
  }

  static Future<void> updateImageDescription(
    String imageId,
    String description,
  ) async {
    try {
      if (!AuthService.isAuthenticated) {
        throw Exception('User authentication required');
      }

      await _firestore.collection(_getUserCollectionPath()).doc(imageId).update(
        {'description': description},
      );
    } catch (e) {
      throw Exception('Failed to update image description: ${e.toString()}');
    }
  }

  static Stream<TaskSnapshot> getUploadProgress(File imageFile) {
    if (!AuthService.isAuthenticated) {
      throw Exception('User authentication required');
    }

    final String fileName = '${_uuid.v4()}.jpg';
    final String filePath = _getUserStoragePath(fileName);
    final Reference ref = _storage.ref().child(filePath);
    final UploadTask uploadTask = ref.putFile(imageFile);

    return uploadTask.snapshotEvents;
  }

  /// Delete all user data (for account deletion)
  static Future<void> deleteAllUserData() async {
    try {
      if (!AuthService.isAuthenticated) {
        throw Exception('User authentication required');
      }

      final userId = AuthService.currentUserId!;

      final ListResult storageList = await _storage
          .ref()
          .child('users/$userId/images')
          .listAll();

      for (final item in storageList.items) {
        await item.delete();
      }

      final QuerySnapshot querySnapshot = await _firestore
          .collection(_getUserCollectionPath())
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete user data: ${e.toString()}');
    }
  }
}
