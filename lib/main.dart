import 'package:flutter/material.dart';
import 'app.dart';
import 'data/local_store.dart';
import 'state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final controller = AppController(await LocalStore.open());
    await controller.load();
    runApp(CourtsideApp(controller: controller));
  } catch (_) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Courtside could not open local storage. Please restart the app. Your saved matches have not been deleted.',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
