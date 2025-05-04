import 'package:flutter/material.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!['en', 'es', 'ca'].contains(locale.languageCode)) return;
    _locale = locale;
    notifyListeners();
  }
}
