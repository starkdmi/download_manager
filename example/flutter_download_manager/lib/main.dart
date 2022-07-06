import 'package:flutter/material.dart';
import 'package:flutter_download_manager/app.dart';

void main() {

  // TODO 
  // 1. Check if file already exists (now progress automatically continues if file exist but initial state is - not started)
  // 2. Home()._reset() action button
  // 3. permission_handler
  // 4. Setup()
  // - isolates count
  // - directory picker 
  // 5. Global static class to separate UI from Core, all calls to DM from here

  runApp(const App());
}