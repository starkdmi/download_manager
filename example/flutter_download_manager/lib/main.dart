import 'package:flutter/material.dart';
import 'package:isolated_download_manager/download_manager.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({ super.key }) : super();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Download Manager",
      theme: ThemeData(
        // primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red.shade400) 
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  static const url = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
  static const directory = "/Users/starkdmi/Downloads/test";

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    
    // Initialize
    DownloadManager.instance.init(isolates: 1, directory: "/Users/starkdmi/Downloads/test");
  }

  @override
  void dispose() {
    // Clean-up isolates
    DownloadManager.instance.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Download Manager"),
      ),
      // body: Column(children: [
      body: const Center(child: 
        Item(name: "BigBuckBunny.mp4", url: Home.url)
      )
      // ]),
    );
  }
}

class Item extends StatefulWidget {
  const Item({ super.key, required this.name, required this.url }) : super();
  final String name;
  final String url;

  @override
  State<Item> createState() => _ItemState();
}

class _ItemState extends State<Item> {
  DownloadRequest? _request;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _request?.events, 
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // _retry, replay_rounded
          return const SizedBox();
        }

        if (snapshot.hasData) {
          final data = snapshot.data!;
          if (data is DownloadEvent) {
            // state
            switch (data) {
              case DownloadEvent.queued:
              case DownloadEvent.started:
                return const CircularProgressIndicator();
              case DownloadEvent.paused:
                // _resume, downloading_rounded
                return const SizedBox();
              case DownloadEvent.resumed:
                return const CircularProgressIndicator();
              case DownloadEvent.cancelled:
                // _download, downloading_rounded
                return const SizedBox();
              case DownloadEvent.finished:
                // openfile open and delete (slidable?) 
                // _open, file_open_rounded/open_in_new
                // _delete, delete_rounded
                return const SizedBox();
            }
          } else if (data is double) { 
            // progress
            return CircularProgressIndicator(value: data);
          } else {
            // unknown state
            return const SizedBox();
          }
        } else {
          // not started - shouldn't appear
          // _download, downloading_rounded
          return const SizedBox();
        }
      },
    );
  }
  
  void _download() => setState(() => _request = DownloadManager.instance.add(widget.url));
  void _open() => OpenFile.open("${Home.directory}/${widget.name}");
  void _pause() => _request?.pause();
  void _resume() => _request?.resume();
  void _cancel() => _request?.cancel();
  Future<void> _delete() async {
    // delete file and reset request
    final file = File("${Home.directory}/${widget.name}");
    if (await file.exists()) {
      await file.delete();
    }
    setState(() => _request = null);
  }
}

class ButtonWidget extends StatelessWidget {
  const ButtonWidget({ super.key, required this.icon, this.onPressed }) : super();
  final IconData icon;
  final Function()? onPressed;

  static const iconSize = 56.0;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return IconButton(
      onPressed: onPressed, 
      icon: Icon(icon, size: iconSize, color: primary)
    );
  }
}

class NameWidget extends StatelessWidget {
  const NameWidget({ super.key, required this.name }) : super();
  final String name;

  @override
  Widget build(BuildContext context) {
    return Text(name);
  }
}

// TODO
// stateless widget for each of those states 
// one satteful widget with request and stream builder

// 1. if (snapshot.hasError) - error
// NameWidget(name), ButtonWidget(retry)

// 2. unknown, .cancelled, if (!snapshot.hasData) - not started 
// NameWidget(name), ButtonWidget(download)

// 3. .paused
// NameWidget(name), ButtonWidget(resume)

// 4. finished
// NameWidget(name), ButtonWidget(open), ButtonWidget(delete)/Slidable(delete)

// 5. .queued, .started, .resumed - loading
// NameWidget(name), Stack [Loading(infinity), ButtonWidget(Cancel)]

// 6. double - progress 
// NameWidget(name), Stack [Loading(progress), ButtonWidget(Cancel)]
