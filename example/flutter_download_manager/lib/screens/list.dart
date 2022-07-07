import 'package:flutter/material.dart';
import 'package:flutter_download_manager_example/widgets/list_item.dart';

import 'package:flutter_download_manager_example/globals.dart';
import 'package:isolated_download_manager/download_manager.dart';

class DownloadList extends StatefulWidget {
  const DownloadList({ super.key }) : super();

  static final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
    
  @override
  State<DownloadList> createState() => _DownloadListState();
}

class _DownloadListState extends State<DownloadList> {
  var _listViewKey = const ValueKey("listView");
  int _refreshIndex = 0;
  
  final _items = Globals.links.entries;

  @override
  void initState() {
    super.initState();
    
    // Initialize
    DownloadManager.instance.init(isolates: Globals.isolates, directory: Globals.directory);
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
      key: DownloadList.scaffoldKey,
      appBar: AppBar(
        title: const Text("Download Manager"),
        actions: [
          IconButton(onPressed: _reset, icon: const Icon(Icons.restore_page_rounded)) // restore replay_rounded
        ],
      ),
      body: ListView.builder(
        key: _listViewKey,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items.elementAt(index);
          return DownloadItem(name: item.key, url: item.value);
        }
      )
    );
  }

  void _reset() async {
    // hide error banner
    final context = DownloadList.scaffoldKey.currentState?.context;
    if (context != null) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearMaterialBanners();
    }

    // cancel all running requests
    DownloadManager.instance.cancelAll();
    await Future.delayed(const Duration(seconds: 1));

    // refresh list (reset child states)
    setState(() => _listViewKey = ValueKey("listView_${_refreshIndex++}"));

    // remove files
    await Globals.clean();
  }
}