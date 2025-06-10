part of 'image_upload_cubit.dart';

abstract class ImageUploadState extends Equatable {
  const ImageUploadState();

  @override
  List<Object?> get props => [];
}

class ImageUploadInitial extends ImageUploadState {}

class ImageUploading extends ImageUploadState {}

class ImageUploadSuccess extends ImageUploadState {
  final UploadedImage uploadedImage;

  const ImageUploadSuccess(this.uploadedImage);

  @override
  List<Object?> get props => [uploadedImage];
}

class ImageUploadFailure extends ImageUploadState {
  final String error;

  const ImageUploadFailure(this.error);

  @override
  List<Object?> get props => [error];
}
