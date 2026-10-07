import 'package:flutter/material.dart';

class AppThemeManager extends ChangeNotifier {
  static final AppThemeManager instance = AppThemeManager._internal();
  AppThemeManager._internal();

  Color _backgroundColor = const Color(0xFFE4B1FA); // Lilás claro (Padrão do app)
  double _fontScale = 1.0;
  bool _isPremium = false;

  Color get backgroundColor => _backgroundColor;
  bool get isPremium => _isPremium;

  // Cor de destaque para cards selecionados ou gradientes
  Color get cardSelectionColor {
    if (_backgroundColor == const Color(0xFFB3E5FC)) {
      return const Color(0xFFE1F5FE); // Azul super claro
    }
    return const Color(0xFFF1DBED); // Lilás super claro
  }

  // Cor do texto dentro de botões coloridos
  Color get buttonTextColor => Colors.white;

  // Cor principal usada em botões
  Color get primaryColor {
    if (_backgroundColor == const Color(0xFFB3E5FC)) {
      return const Color(0xFF1565C0); // Azul escuro para o tema Azul Bebê
    }
    return const Color(0xFF9C72AD); // Lilás escuro para o tema padrão
  }

  Color get secondaryColor {
    if (_backgroundColor == const Color(0xFFB3E5FC)) {
      return const Color(0xFF64B5F6); // Azul médio
    }
    return const Color(0xFFAA8ED6); // Lilás médio
  }

  Color get borderColor {
    if (_backgroundColor == const Color(0xFFB3E5FC)) {
      return const Color(0xFF0D47A1); // Azul mais escuro
    }
    return const Color(0xFF4B3B63); // Roxo escuro
  }

  double get fontScale => _fontScale;

  void setBackgroundColor(Color color) {
    if (_backgroundColor != color) {
      _backgroundColor = color;
      notifyListeners();
    }
  }

  void setFontScale(double scale) {
    if (_fontScale != scale) {
      _fontScale = scale;
      notifyListeners();
    }
  }

  void setPremiumUser(bool value) {
    if (_isPremium != value) {
      _isPremium = value;
      notifyListeners();
    }
  }
}
