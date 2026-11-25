import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/local_storage_service.dart';
import 'services/weather_api_service.dart';
import 'theme/app_theme.dart';
import 'viewmodels/search_viewmodel.dart';
import 'viewmodels/weather_viewmodel.dart';
import 'views/home_weather_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = WeatherApiService();
  final storageService = LocalStorageService();

  runApp(
    CuacaApp(
      apiService: apiService,
      storageService: storageService,
    ),
  );
}

class CuacaApp extends StatelessWidget {
  final WeatherApiService apiService;
  final LocalStorageService storageService;

  const CuacaApp({
    super.key,
    required this.apiService,
    required this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => WeatherViewModel(
            apiService: apiService,
            storageService: storageService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SearchLocationViewModel(
            apiService: apiService,
            storageService: storageService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'CuacaKu - Open-Meteo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeWeatherScreen(),
      ),
    );
  }
}
