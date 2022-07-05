import 'package:isolated_download_manager/download_manager.dart';
import 'package:test/test.dart';

void main() {
  group("Simple tests", () {
    final manager = DownloadManager.instance;

    setUp(() async {
      await manager.init(isolates: 2, directory: "/Users/starkdmi/Downloads/test");
      await Future.delayed(const Duration(seconds: 1));
    });

    tearDown(() async {
      await manager.dispose();
    });

    test("Initialized", () {
      expect(manager.initialized, isTrue);
    });
  });
}
