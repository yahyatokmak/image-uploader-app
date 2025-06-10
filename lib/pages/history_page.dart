import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubits/auth/auth_cubit.dart';
import '../cubits/history/history_cubit.dart';
import '../models/uploaded_image.dart';
import '../theme/app_theme.dart';
import 'result_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    // Load images when page initializes - only if authenticated
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<HistoryCubit>().loadImages();
    }
  }

  void _showDeleteConfirmation(UploadedImage image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Image'),
          content: const Text(
            'Are you sure you want to delete this image? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<HistoryCubit>().deleteImage(image);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showDebugInfo(UploadedImage image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Debug Information'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ID: ${image.id}'),
                const SizedBox(height: 8),
                Text('File Name: ${image.fileName}'),
                const SizedBox(height: 8),
                Text('File Size: ${image.fileSize} bytes'),
                const SizedBox(height: 8),
                Text('Upload Date: ${image.uploadedAt}'),
                const SizedBox(height: 8),
                Text('Description: ${image.description ?? 'None'}'),
                const SizedBox(height: 8),
                const Text('Download URL:'),
                const SizedBox(height: 4),
                SelectableText(
                  image.downloadUrl,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {}); // Refresh the UI
                _showSnackBar('Image refreshed');
              },
              child: const Text('Refresh Image'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
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

  Widget _buildImageWidget(UploadedImage image) {
    return Image.network(
      image.downloadUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: AppTheme.surfaceColor,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('Image load error: $error for URL: ${image.downloadUrl}');
        return Container(
          color: AppTheme.surfaceColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: AppTheme.errorColor, size: 20),
              const SizedBox(height: 2),
              Text(
                'Load Failed',
                style: TextStyle(fontSize: 10, color: AppTheme.errorColor),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload History'),
        actions: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              if (authState is AuthAuthenticated) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context.read<HistoryCubit>().refreshImages();
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: AppTheme.secondaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Authentication Required',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please sign in to view your image history',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return BlocConsumer<HistoryCubit, HistoryState>(
            listener: (context, state) {
              if (state is HistoryPageFailureState) {
                _showSnackBar('Error: ${state.error}');
              }
            },
            builder: (context, state) {
              if (state is HistoryPageLoadingState) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is HistoryPageFailureState) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load images',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.error,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<HistoryCubit>().loadImages();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                );
              }

              if (state is HistoryPageLoadedState) {
                if (state.images.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 64,
                          color: AppTheme.secondaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No images uploaded yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload your first image and see it here',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Upload Image'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<HistoryCubit>().refreshImages();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.images.length,
                    itemBuilder: (context, index) {
                      final image = state.images[index];
                      return _buildImageCard(image);
                    },
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          );
        },
      ),
      floatingActionButton: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is AuthAuthenticated) {
            return FloatingActionButton(
              onPressed: () {
                Navigator.pop(context);
              },
              tooltip: 'Upload New Image',
              child: const Icon(Icons.add_photo_alternate),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildImageCard(UploadedImage image) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ResultPage(uploadedImage: image, isFromUpload: false),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppTheme.surfaceColor,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImageWidget(image),
                ),
              ),

              const SizedBox(width: 16),

              // Image Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      image.fileName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'dd MMM yyyy • HH:mm',
                      ).format(image.uploadedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (image.description != null &&
                        image.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        image.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppTheme.secondaryColor),
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultPage(
                            uploadedImage: image,
                            isFromUpload: false,
                          ),
                        ),
                      );
                      break;
                    case 'debug':
                      _showDebugInfo(image);
                      break;
                    case 'delete':
                      _showDeleteConfirmation(image);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility),
                        SizedBox(width: 8),
                        Text('View Details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'debug',
                    child: Row(
                      children: [
                        Icon(Icons.bug_report),
                        SizedBox(width: 8),
                        Text('Debug Info'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
