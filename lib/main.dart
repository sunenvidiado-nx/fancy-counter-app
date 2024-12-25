import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/features/counter/counter_page_view_model.dart';

void main() {
  runZoned(() async {
    WidgetsFlutterBinding.ensureInitialized();

    _setUpLicenses();
    _setUpNavigationAndStatusBarColors();
    await _setUpDiAndViewModels();

    runApp(const App());
  });
}

Future<void> _setUpDiAndViewModels() async {
  final sharedPrefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );

  // Register dependencies
  GetIt.I
    ..registerLazySingleton(() => sharedPrefs)
    ..registerLazySingleton(Random.new);

  // Register view models
  GetIt.I.registerFactory(() => CounterPageViewModel(GetIt.I(), GetIt.I()));
}

void _setUpNavigationAndStatusBarColors() {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black.withValues(alpha: 255),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

void _setUpLicenses() {
  LicenseRegistry.addLicense(() async* {
    final license =
        await rootBundle.loadString('assets/google_fonts/Teko/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
}
