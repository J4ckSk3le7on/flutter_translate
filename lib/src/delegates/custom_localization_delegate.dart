import 'package:flutter/widgets.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:flutter_translate/src/services/locale_service.dart';
import 'package:flutter_translate/src/constants/constants.dart';
import 'package:flutter_translate/src/validators/configuration_validator.dart';

class CustomLocalizationDelegate extends LocalizationsDelegate<Localization> {
  Locale? _currentLocale;
  final Locale fallbackLocale;
  final List<Locale> supportedLocales;
  final Map<Locale, String> supportedLocalesMap;
  final ITranslatePreferences? preferences;

  // Constructor
  CustomLocalizationDelegate({
    required this.fallbackLocale,
    required this.supportedLocales,
    required this.supportedLocalesMap,
    this.preferences,
  });

  // Getter para obtener el locale actual
  Locale get currentLocale => _currentLocale!;

  // Cambia el idioma de la aplicación
  Future changeLocale(Locale newLocale) async {
    var isInitializing = _currentLocale == null;

    var locale = LocaleService.findLocale(newLocale, supportedLocales) ?? fallbackLocale;

    if (_currentLocale == locale) return;

    var localizedContent = await LocaleService.getLocaleContent(locale, supportedLocalesMap);

    Localization.load(localizedContent);

    _currentLocale = locale;

    if (!isInitializing && preferences != null) {
      await preferences!.savePreferredLocale(locale);
    }
  }

  @override
  Future<Localization> load(Locale newLocale) async {
    if (currentLocale != newLocale) {
      await changeLocale(newLocale);
    }
    return Localization.instance;
  }

  @override
  bool isSupported(Locale? locale) => locale != null;

  @override
  bool shouldReload(LocalizationsDelegate<Localization> old) => true;

  // Método estático para crear el delegado
  static Future<CustomLocalizationDelegate> create({
    required String fallbackLocale,
    required List<String> supportedLocales,
    String basePath = Constants.localizedAssetsPath,
    ITranslatePreferences? preferences,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    var fallback = localeFromString(fallbackLocale);
    var localesMap = await LocaleService.getLocalesMap(supportedLocales, basePath);
    var locales = localesMap.keys.toList();

    ConfigurationValidator.validate(fallback, locales);

    var delegate = CustomLocalizationDelegate(
      fallbackLocale: fallback,
      supportedLocales: locales,
      supportedLocalesMap: localesMap,
      preferences: preferences,
    );

    if (!await delegate._loadPreferences()) {
      await delegate._loadDeviceLocale();
    }

    return delegate;
  }

  // Carga las preferencias guardadas
  Future<bool> _loadPreferences() async {
    if (preferences == null) return false;

    Locale? locale;

    try {
      locale = await preferences!.getPreferredLocale();
    } catch (e) {
      return false;
    }

    if (locale != null) {
      await changeLocale(locale);
      return true;
    }

    return false;
  }

  // Carga el locale del dispositivo
  Future _loadDeviceLocale() async {
    try {
      var locale = getCurrentLocale();

      if (locale != null) {
        await changeLocale(locale);
      }
    } catch (e) {
      await changeLocale(fallbackLocale);
    }
  }
}
