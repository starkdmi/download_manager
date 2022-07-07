import 'package:flutter/material.dart';
import 'package:flutter_download_manager/download_manager_flutter.dart';
import 'package:flutter_download_manager_example/widgets/button.dart';
import 'package:flutter_download_manager_example/widgets/progress.dart';

class CardWidget extends StatelessWidget {
  const CardWidget({ 
    super.key, 
    required this.name, 
    required this.state, 
    this.progress, 
    this.buttonLeft, 
    this.buttonRight 
  }) : super();

  final String name;
  final DownloadWidgetState state;
  final double? progress;
  final ButtonWidget? buttonLeft;
  final ButtonWidget? buttonRight;

  @override
  Widget build(BuildContext context) {
    return Card(child: 
      ListTile(
        contentPadding: const EdgeInsets.only(left: 24, right: 16),
        title: Text(name), 
        subtitle: ProgressWidget(state: state, progress: progress),
        // leading: Image(logo),
        trailing: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 64, child: Center(child: buttonLeft)),
          SizedBox(width: 64, child: Center(child: buttonRight)),
        ]),
      )
    );
  }
}
