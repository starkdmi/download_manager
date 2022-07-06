import 'package:flutter/material.dart';
import 'package:flutter_download_manager/setup.dart';
import 'package:flutter_download_manager/list_item.dart';

import 'package:isolated_download_manager/download_manager.dart';

class Home extends StatefulWidget {
  const Home({ super.key }) : super();

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    
    // Initialize
    DownloadManager.instance.init(isolates: Setup.isolates, directory: Setup.directory);
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
        actions: [
          IconButton(onPressed: _reset, icon: const Icon(Icons.replay_rounded)) // restore
        ],
      ),
      // body: Column(children: [
      body: const Center(child: 
        DownloadItem(name: "GoLang", url: Setup.url),
      )
      // ]),
    );
  }

  void _reset() {
    // TODO
    // cancel all running requests
    // remove files from request.path ?
    // remove files in default directory 
  }
}