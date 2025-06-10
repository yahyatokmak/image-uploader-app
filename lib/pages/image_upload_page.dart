import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../cubits/auth/auth_cubit.dart';
import '../cubits/image_upload/image_upload_cubit.dart';
import '../cubits/history/history_cubit.dart';
import '../theme/app_theme.dart';
import 'result_page.dart';

class ImageUploadPage extends StatefulWidget {
  const ImageUploadPage({super.key});

  @override
  State<ImageUploadPage> createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    try {
      // Check camera permission
      final cameraStatus = await Permission.camera.status;

      if (cameraStatus.isPermanentlyDenied) {
        _showPermissionSettingsDialog('Camera');
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
        preferredCameraDevice: CameraDevice.rear,
        requestFullMetadata: false,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Camera access error: ${e.toString()}');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      // Check photos permission
      final photosStatus = await Permission.photos.status;

      if (photosStatus.isPermanentlyDenied) {
        _showPermissionSettingsDialog('Photos');
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Gallery access error: ${e.toString()}');
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _uploadImage() {
    if (_selectedImage == null) {
      _showSnackBar('Please select an image first');
      return;
    }

    // Check authentication before upload
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      _showSnackBar('User authentication required');
      return;
    }

    context.read<ImageUploadCubit>().uploadImage(
      imageFile: _selectedImage!,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedImage = null;
      _descriptionController.clear();
    });
  }

  void _showPermissionSettingsDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$permissionType Permission Required'),
          content: Text(
            '$permissionType permission has been permanently denied. Please enable it in Settings to use this feature.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Image'),
        actions: [
          // User info button
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              if (authState is AuthAuthenticated) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.account_circle),
                  onSelected: (value) {
                    switch (value) {
                      case 'user_info':
                        _showUserInfo(authState.user.uid);
                        break;
                      case 'sign_out':
                        context.read<AuthCubit>().signOut();
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'user_info',
                      child: Row(
                        children: [
                          Icon(Icons.info),
                          SizedBox(width: 8),
                          Text('User Information'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'sign_out',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('Sign Out'),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/history');
            },
          ),
        ],
      ),
      body: BlocListener<ImageUploadCubit, ImageUploadState>(
        listener: (context, state) {
          if (state is ImageUploadSuccess) {
            // Add the image to history
            context.read<HistoryCubit>().addImage(state.uploadedImage);

            // Navigate to result page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResultPage(
                  uploadedImage: state.uploadedImage,
                  isFromUpload: true,
                ),
              ),
            );
          } else if (state is ImageUploadFailure) {
            _showSnackBar('Upload failed: ${state.error}');
          }
        },
        child: BlocBuilder<ImageUploadCubit, ImageUploadState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Auth status indicator
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      if (authState is AuthAuthenticated) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.successColor.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppTheme.successColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'User ID: ${authState.user.uid.substring(0, 8)}...',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppTheme.successColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Image Preview Section
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.secondaryColor,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: AppTheme.surfaceColor,
                      ),
                      child: _selectedImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 80,
                                  color: AppTheme.secondaryColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No image selected',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the button below to select an image',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: state is ImageUploading
                              ? null
                              : _showImageSourceDialog,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Select Image'),
                        ),
                      ),
                      if (_selectedImage != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: state is ImageUploading
                                ? null
                                : _clearSelection,
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Upload Button
                  ElevatedButton.icon(
                    onPressed: state is ImageUploading || _selectedImage == null
                        ? null
                        : _uploadImage,
                    icon: state is ImageUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(
                      state is ImageUploading ? 'Uploading...' : 'Upload Image',
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showUserInfo(String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('User Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User ID: $userId'),
              const SizedBox(height: 8),
              const Text('Login Type: Anonymous'),
              const SizedBox(height: 16),
              const Text(
                'All your images are stored under this user account.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
