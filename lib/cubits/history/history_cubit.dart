import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/firebase_service.dart';
import '../../models/uploaded_image.dart';

part 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit() : super(HistoryPageLoadingState());

  /// Load all uploaded images
  Future<void> loadImages() async {
    try {
      emit(HistoryPageLoadingState());

      final List<UploadedImage> images =
          await FirebaseService.getAllUploadedImages();

      emit(HistoryPageLoadedState(images));
    } catch (e) {
      emit(HistoryPageFailureState(e.toString()));
    }
  }

  /// Refresh the image list
  Future<void> refreshImages() async {
    await loadImages();
  }

  /// Delete an image from the list
  Future<void> deleteImage(UploadedImage image) async {
    try {
      if (state is HistoryPageLoadedState) {
        final currentState = state as HistoryPageLoadedState;

        // Show loading state while deleting
        emit(HistoryPageLoadingState());

        // Delete from Firebase
        await FirebaseService.deleteUploadedImage(image);

        // Remove from local list and update state
        final updatedImages = currentState.images
            .where((img) => img.id != image.id)
            .toList();

        emit(HistoryPageLoadedState(updatedImages));
      }
    } catch (e) {
      emit(HistoryPageFailureState(e.toString()));
    }
  }

  /// Add a new image to the list (used when navigating back from upload)
  void addImage(UploadedImage image) {
    if (state is HistoryPageLoadedState) {
      final currentState = state as HistoryPageLoadedState;
      final updatedImages = [image, ...currentState.images];
      emit(HistoryPageLoadedState(updatedImages));
    }
  }
}
