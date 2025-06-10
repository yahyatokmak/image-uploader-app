import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/firebase_service.dart';
import '../../models/uploaded_image.dart';

part 'image_upload_state.dart';

class ImageUploadCubit extends Cubit<ImageUploadState> {
  ImageUploadCubit() : super(ImageUploadInitial());

  /// Upload image to Firebase
  Future<void> uploadImage({
    required File imageFile,
    String? description,
  }) async {
    try {
      emit(ImageUploading());

      final UploadedImage uploadedImage = await FirebaseService.uploadImage(
        imageFile: imageFile,
        description: description,
      );

      print('Upload successful! Image ID: ${uploadedImage.id}');
      emit(ImageUploadSuccess(uploadedImage));
    } catch (e) {
      print('Upload failed: $e');
      emit(ImageUploadFailure(e.toString()));
    }
  }

  /// Reset to initial state
  void resetState() {
    emit(ImageUploadInitial());
  }

  /// Clear any error state
  void clearError() {
    if (state is ImageUploadFailure) {
      emit(ImageUploadInitial());
    }
  }
}
