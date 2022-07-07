import 'package:flutter/material.dart';
import 'package:flutter_download_manager_example/widgets/card.dart';
import 'package:flutter_download_manager_example/widgets/button.dart';
import 'package:flutter_download_manager/download_manager_flutter.dart';

import 'package:flutter_download_manager_example/globals.dart';
import 'package:isolated_download_manager/download_manager.dart';
import 'package:open_file/open_file.dart';
import 'dart:io' show File;

class DownloadItem extends StatefulWidget {
  const DownloadItem({ super.key, required this.name, required this.url }) : super();
  final String name;
  final String url;

  @override
  State<DownloadItem> createState() => _DownloadItemState();
}

class _DownloadItemState extends State<DownloadItem> {
  DownloadRequest? _request;

  @override
  Widget build(BuildContext context) {
    return DownloadWidget(
      request: _request, 
      builder: (context, state, progress, error) {
        switch (state) {
          case DownloadWidgetState.initial:
            return CardWidget(
              name: widget.name, 
              state: state, 
              buttonRight: ButtonWidget(onPressed: _download, icon: Icons.downloading_rounded) // download_rounded
            );
          case DownloadWidgetState.queued:
            return CardWidget(
              name: widget.name, 
              state: state,
              buttonLeft: ButtonWidget(onPressed: _cancel, icon: Icons.close_rounded),
            );
          case DownloadWidgetState.failed:
            // showErrorBanner(context, error);
            return CardWidget(
              name: widget.name, 
              state: state, 
              buttonRight: ButtonWidget(onPressed: _download, icon: Icons.replay_rounded) // sync_rounded
            );
          case DownloadWidgetState.downloading:
            return CardWidget(
              name: widget.name, 
              state: state,
              progress: progress,
              buttonLeft: ButtonWidget(onPressed: _cancel, icon: Icons.close_rounded), // clear_rounded
              buttonRight: ButtonWidget(onPressed: _pause, icon: Icons.pause_rounded)
            );
          case DownloadWidgetState.paused:
            return CardWidget(
              name: widget.name, 
              state: state, 
              progress: progress, 
              buttonLeft: ButtonWidget(onPressed: _cancel, icon: Icons.close_rounded),
              buttonRight: ButtonWidget(onPressed: _resume, icon: Icons.play_arrow_rounded)
            );
          case DownloadWidgetState.downloaded:
            return CardWidget(
              name: widget.name, 
              state: state,
              buttonLeft: ButtonWidget(onPressed: _open, icon: Icons.insert_drive_file_rounded),
              buttonRight: ButtonWidget(onPressed: _delete, icon: Icons.delete_rounded)
            );
        }
      }
    );

    // Using DownloadUrlWidget which stores request and provide controling interface
    /*return DownloadUrlWidget(
      url: widget.url,
      // path: path,
      // manager: DownloadManager.instance,
      builder: (context, controller, state, progress, error, request) {
        switch (state) {
          case DownloadWidgetState.initial:
            return CardWidget(
              name: widget.name, 
              state: state, 
              buttonRight: ButtonWidget(onPressed: controller.download, icon: Icons.downloading_rounded) // download_rounded
            );
          case DownloadWidgetState.queued:
            return CardWidget(
              name: widget.name, 
              state: state,
              buttonLeft: ButtonWidget(onPressed: controller.cancel, icon: Icons.close_rounded),
            );
          case DownloadWidgetState.failed:
            // showErrorBanner(context, error);
            return CardWidget(
              name: widget.name, 
              state: state, 
              buttonRight: ButtonWidget(onPressed: controller.download, icon: Icons.replay_rounded) // sync_rounded
            );
          case DownloadWidgetState.downloading:
            return CardWidget(
              name: widget.name, 
              state: state,
              progress: progress,
              buttonLeft: ButtonWidget(onPressed: controller.cancel, icon: Icons.close_rounded), // clear_rounded
              buttonRight: ButtonWidget(onPressed: controller.pause, icon: Icons.pause_rounded)
            );
          case DownloadWidgetState.paused:
            return CardWidget(
              name: widget.name, 
              state: state, 
              progress: progress, 
              buttonLeft: ButtonWidget(onPressed: controller.cancel, icon: Icons.close_rounded),
              buttonRight: ButtonWidget(onPressed: controller.resume, icon: Icons.play_arrow_rounded)
            );
          case DownloadWidgetState.downloaded:
            return CardWidget(
              name: widget.name, 
              state: state,
              buttonLeft: ButtonWidget(onPressed: _open, icon: Icons.insert_drive_file_rounded),
              buttonRight: ButtonWidget(onPressed: _delete, icon: Icons.delete_rounded)
            );
        }
      }
    );*/
  }

  /*void showErrorBanner(BuildContext context, Object? error) {
    if (error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showMaterialBanner(
          MaterialBanner(
            content: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(error.toString())), 
            actions: [
              IconButton(onPressed: () { messenger.clearMaterialBanners(); }, icon: const Icon(Icons.close_rounded))
            ])
        );
      });
    }
  }*/
  
  String get path {
    final uri = Uri.parse(widget.url);
    final lastSegment = uri.pathSegments.last;
    final filename = lastSegment.substring(lastSegment.lastIndexOf("/") + 1);
    final extension = filename.split(".").last;
    return "${Globals.directory}/${widget.name}.$extension";
  }

  void _download() => setState(() => _request = DownloadManager.instance.download(widget.url, path: path));
  void _pause() => _request?.pause();
  void _resume() => _request?.resume();
  void _cancel() => _request?.cancel();

  void _open() => OpenFile.open(path);
  
  Future<void> _delete() async {
    // delete file and reset request
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    setState(() => _request = null);
  }
}
