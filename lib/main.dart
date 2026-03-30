import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/mock/mock_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  runApp(
    ProviderScope(
      // debug 模式下使用 mock 数据，release 模式用真实 providers
      overrides: kDebugMode ? mockOverrides : const [],
      child: const WatermelonApp(),
    ),
  );
}
