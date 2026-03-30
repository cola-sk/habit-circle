import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final token = await storage.read(key: 'jwt_token');

  runApp(
    ProviderScope(
      overrides: [
        authStateNotifierProvider.overrideWith(
          (ref) => AuthStateNotifier(token != null),
        ),
      ],
      child: const WatermelonApp(),
    ),
  );
}
