part of 'history_cubit.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryPageLoadingState extends HistoryState {}

class HistoryPageLoadedState extends HistoryState {
  final List<UploadedImage> images;

  const HistoryPageLoadedState(this.images);

  @override
  List<Object?> get props => [images];
}

class HistoryPageFailureState extends HistoryState {
  final String error;

  const HistoryPageFailureState(this.error);

  @override
  List<Object?> get props => [error];
}
