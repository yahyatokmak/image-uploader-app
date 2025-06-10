import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/uploaded_image.dart';
import '../theme/app_theme.dart';

class ResultPage extends StatefulWidget {
  final UploadedImage uploadedImage;
  final bool isFromUpload;

  const ResultPage({
    super.key,
    required this.uploadedImage,
    this.isFromUpload = false,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.isFromUpload) {
              // Navigate back to home and refresh history
              Navigator.popUntil(context, (route) => route.isFirst);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success Message (only shown when coming from upload)
            if (widget.isFromUpload) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.successColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.successColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Image uploaded successfully!',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Image Display
            Container(
              height: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.uploadedImage.downloadUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppTheme.surfaceColor,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print(
                      'Image load error: $error for URL: ${widget.uploadedImage.downloadUrl}',
                    );
                    return Container(
                      color: AppTheme.surfaceColor,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 48,
                            color: AppTheme.errorColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load image',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {});
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Image Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Image Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    _buildInfoRow(
                      context,
                      Icons.image,
                      'File Name',
                      widget.uploadedImage.fileName,
                    ),

                    const SizedBox(height: 12),

                    _buildInfoRow(
                      context,
                      Icons.calendar_today,
                      'Upload Date',
                      DateFormat(
                        'dd MMM yyyy • HH:mm',
                      ).format(widget.uploadedImage.uploadedAt),
                    ),

                    const SizedBox(height: 12),

                    _buildInfoRow(
                      context,
                      Icons.storage,
                      'File Size',
                      _formatFileSize(widget.uploadedImage.fileSize),
                    ),

                    if (widget.uploadedImage.description != null &&
                        widget.uploadedImage.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        Icons.description,
                        'Description',
                        widget.uploadedImage.description!,
                      ),
                    ],

                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      Icons.link,
                      'Download URL',
                      widget.uploadedImage.downloadUrl.length > 50
                          ? '${widget.uploadedImage.downloadUrl.substring(0, 50)}...'
                          : widget.uploadedImage.downloadUrl,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/history');
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('View History'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Upload More'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.secondaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
