import 'package:flutter/material.dart';


enum ProgressState {
  initial, queued, failed, downloading, paused, downloaded
}

class ProgressWidget extends StatelessWidget {
  const ProgressWidget({ super.key, required this.state, this.progress }) : super();
  final ProgressState state;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final String progressText;
    Widget? progressWidget;
    switch (state) {
      case ProgressState.initial:
        progressText = "Not started";
        break;
      case ProgressState.queued:
        progressText = "Queued";
        progressWidget = const Icon(Icons.menu_rounded, size: 18);
        break;
      case ProgressState.failed:
        progressText = "Downloading failed";
        progressWidget = const Icon(Icons.error_rounded, size: 18);
        break;
      case ProgressState.downloading:
        if (progress == null) {
          progressText = "Downloading";
          progressWidget = const SizedBox(height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)
          );
        } else {
          progressText = "Downloading ${formatProgress(progress)}";
          progressWidget = SizedBox(height: 12, child: 
            Stack(children: [
              CircularProgressIndicator(value: 1.0, strokeWidth: 2, color: Colors.grey.withOpacity(0.2)),
              CircularProgressIndicator(value: progress, strokeWidth: 2, color: Colors.grey)
            ])
          );
        }
        break;
      case ProgressState.paused:
        progressText = "Paused ${formatProgress(progress)}";
        progressWidget = const Icon(Icons.pause, size: 18);
        // progressWidget = const SizedBox();
        break;
      case ProgressState.downloaded:
        progressText = "Downloaded";
        progressWidget = const Icon(Icons.done_rounded, size: 18);
        break;
    }

    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (state != ProgressState.initial) SizedBox(width: 12, child: progressWidget),
      if (state != ProgressState.initial) const SizedBox(width: 8), 
      Text(progressText), 
    ]);
  }

  String formatProgress(progress) => "${(progress! * 100).toStringAsFixed(0)}%";
}