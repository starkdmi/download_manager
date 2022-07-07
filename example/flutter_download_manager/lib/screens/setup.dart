import 'package:flutter/material.dart';
import 'package:flutter_download_manager_example/globals.dart';
import 'dart:io' show Platform;

class Setup extends StatelessWidget {
  const Setup({ super.key }) : super();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Download Manager"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child:
            Text(
              "Pick the number of isolates used for downloading. While navigating to the next screen isolates will be spawn", 
              textAlign: TextAlign.center
            )
          ),

          StatefulBuilder(builder: (context, setState) {
            int? value = Globals.isolates;
            final primary = Theme.of(context).colorScheme.primary;
            return DropdownButton<int>(
              value: value,
              icon: Icon(Icons.arrow_drop_down, color: primary),
              style: TextStyle(color: primary),
              underline: Container(height: 2, color: primary),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  Globals.isolates = newValue;
                  setState(() => value = newValue);
                }
              },
              items: [
                for (int i = 1; i <= Platform.numberOfProcessors - 3; i++)
                  DropdownMenuItem<int>(value: i, child: Text(i.toString()))
              ],
            );
          }),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed("/home"), 
            child: const Text("Let's go")
          )
        ]
      )
    );
  }
}