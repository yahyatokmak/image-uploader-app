import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UploadedImage extends Equatable {
  final String id;
  final String downloadUrl;
  final String fileName;
  final DateTime uploadedAt;
  final int fileSize;
  final String? description;

  const UploadedImage({
    required this.id,
    required this.downloadUrl,
    required this.fileName,
    required this.uploadedAt,
    required this.fileSize,
    this.description,
  });

  // Convert from Firestore document
  factory UploadedImage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UploadedImage(
      id: doc.id,
      downloadUrl: data['downloadUrl'] ?? '',
      fileName: data['fileName'] ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
      fileSize: data['fileSize'] ?? 0,
      description: data['description'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'downloadUrl': downloadUrl,
      'fileName': fileName,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'fileSize': fileSize,
      'description': description,
    };
  }

  // CopyWith method
  UploadedImage copyWith({
    String? id,
    String? downloadUrl,
    String? fileName,
    DateTime? uploadedAt,
    int? fileSize,
    String? description,
  }) {
    return UploadedImage(
      id: id ?? this.id,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      fileName: fileName ?? this.fileName,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      fileSize: fileSize ?? this.fileSize,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [
    id,
    downloadUrl,
    fileName,
    uploadedAt,
    fileSize,
    description,
  ];
}
