import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_translate/src/validators/configuration_validator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:flutter_translate/src/services/locale_service.dart';
import 'package:flutter_translate/src/constants/constants.dart';
import 'package:path_provider/path_provider.dart';

class CustomLocalizationDelegate extends LocalizationsDelegate<Localization> {
  final String basePath;
  final Locale fallbackLocale;
  final List<Locale> supportedLocales;
  final Map<Locale, String> supportedLocalesMap;

  CustomLocalizationDelegate({
    required this.basePath,
    required this.fallbackLocale,
    required this.supportedLocales,
    required this.supportedLocalesMap,
  });

  Future<File> _getTranslationFile(Locale locale) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/translations/${locale.languageCode}.json';
    final file = File(filePath);

    // Si el archivo no existe, devolver el archivo en inglés por defecto
    if (!await file.exists()) {
      print("Translation file not found. Returning default English.");
      return File('${directory.path}/translations/en.json');
    }

    return file;
  }

  @override
  Future<Localization> load(Locale newLocale) async {
    // Si la localización actual es diferente de la nueva, cambian las traducciones
    await changeLocale(newLocale);
    return Localization.instance;
  }

  Future changeLocale(Locale newLocale) async {
    var isInitializing = false; // Asumimos que es la primera vez

    // Verifica si la nueva localidad es compatible
    var locale = LocaleService.findLocale(newLocale, supportedLocales) ?? fallbackLocale;

    var localizedContent = await _loadLocaleContent(locale);
    Localization.load(localizedContent);

    // Si no estamos inicializando, podemos guardar las preferencias
    if (!isInitializing) {
      // Guardar preferencias, si tienes el servicio de preferencias habilitado.
    }

    Intl.defaultLocale = locale.languageCode;
  }

  Future<Map<String, dynamic>> _loadLocaleContent(Locale locale) async {
    try {
      final file = await _getTranslationFile(locale);
      final content = await file.readAsString();
      return jsonDecode(content);
    } catch (e) {
      print("Error loading translation file: $e");
      return {}; // Si hay un error, devolver un mapa vacío
    }
  }

  @override
  bool isSupported(Locale? locale) => locale != null;

  @override
  bool shouldReload(LocalizationsDelegate<Localization> old) => true;

  static Future<CustomLocalizationDelegate> create({
    required String fallbackLocale,
    required List<String> supportedLocales,
    String basePath = Constants.localizedAssetsPath,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    var fallback = localeFromString(fallbackLocale);
    var localesMap = await LocaleService.getLocalesMap(supportedLocales, basePath);
    var locales = localesMap.keys.toList();

    ConfigurationValidator.validate(fallback, locales);

    var delegate = CustomLocalizationDelegate(
      basePath: basePath,
      fallbackLocale: fallback,
      supportedLocales: locales,
      supportedLocalesMap: localesMap,
    );

    return delegate;
  }
}
