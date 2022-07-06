import 'package:flutter/material.dart';
import 'package:flutter_download_manager/setup.dart';
import 'package:flutter_download_manager/card.dart';
import 'package:flutter_download_manager/button.dart';
import 'package:flutter_download_manager/progress.dart';

import 'package:isolated_download_manager/download_manager.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

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
    if (_request == null) {
      // non started
      return ItemWidget(
        name: widget.name, 
        state: ProgressState.initial, 
        buttonRight: ButtonWidget(onPressed: _download, icon: Icons.downloading_rounded) // download_rounded
      );
    }

    return StreamBuilder(
      stream: _request == null ? null : _request!.events, 
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ItemWidget(
            name: widget.name, 
            state: ProgressState.failed, 
            buttonRight: ButtonWidget(onPressed: _download, icon: Icons.replay_rounded) // sync_rounded
          );
        }

        if (snapshot.hasData) {
          final data = snapshot.data!;
          if (data is double) {
            // progress
            return ItemWidget(
              name: widget.name, 
              state: ProgressState.downloading,
              progress: data,
              buttonLeft: ButtonWidget(onPressed: _cancel, icon: Icons.close),
              buttonRight: ButtonWidget(onPressed: _pause, icon: Icons.pause_rounded)
            );
          } 

          switch (data as DownloadState) {
            case DownloadState.queued:
              return ItemWidget(
                name: widget.name, 
                state: ProgressState.queued,
                buttonLeft: ButtonWidget(onPressed: _cancel, icon: Icons.close_rounded),
              );
            case DownloadState.started:
            case DownloadState.resumed:
              return ItemWidget(
                name: widget.name, 
                state: ProgressState.downloading,
                buttonLeft: ButtonWidget(onPressed: _cancel, icon: Icons.close_rounded),
                buttonRight: ButtonWidget(onPressed: _pause, icon: Icons.pause_rounded)
              );
            case DownloadState.paused:
              return ItemWidget(
                name: widget.name, 
                state: ProgressState.paused, 
                progress: _request?.progress, 
                buttonLeft: ButtonWidget(onPressed: _cancel, icon: Icons.close_rounded),
                buttonRight: ButtonWidget(onPressed: _resume, icon: Icons.play_arrow_rounded)
              );
            case DownloadState.cancelled:
              // not started
              return ItemWidget(
                name: widget.name, 
                state: ProgressState.initial, 
                buttonRight: ButtonWidget(onPressed: _download, icon: Icons.downloading_rounded) // download_rounded
              );
            case DownloadState.finished:
              return ItemWidget(
                name: widget.name, 
                state: ProgressState.downloaded,
                progress: 200,
                buttonLeft: ButtonWidget(onPressed: _open, icon: Icons.file_open_rounded), // open_in_new
                buttonRight: ButtonWidget(onPressed: _delete, icon: Icons.delete_rounded)
              );
          }
        }

        // not started
        return ItemWidget(
          name: widget.name, 
          state: ProgressState.initial, 
          buttonRight: ButtonWidget(onPressed: _download, icon: Icons.downloading_rounded) // download_rounded
        );
      },
    );
  }
  
  String get path {
    final uri = Uri.parse(widget.url);
    final lastSegment = uri.pathSegments.last;
    final filename = lastSegment.substring(lastSegment.lastIndexOf("/") + 1);
    final extension = filename.split(".").last;
    return "${Setup.directory}/${widget.name}.$extension";
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
