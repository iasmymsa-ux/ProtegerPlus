import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_model.dart';

class ReminderService extends ChangeNotifier {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal() {
    _loadFromPrefs();
  }

  final List<ReminderModel> _reminders = [];

  List<ReminderModel> get reminders => List.unmodifiable(_reminders);

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString('reminders_key');
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _reminders.clear();
        _reminders.addAll(jsonList.map((j) => ReminderModel.fromJson(j)));
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Erro ao carregar lembretes: $e");
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(_reminders.map((r) => r.toJson()).toList());
      await prefs.setString('reminders_key', jsonString);
    } catch (e) {
      debugPrint("Erro ao salvar lembretes: $e");
    }
  }

  void addReminder(ReminderModel reminder) {
    _reminders.add(reminder);
    _saveToPrefs();
    notifyListeners();
  }

  void updateReminder(ReminderModel updatedReminder) {
    final index = _reminders.indexWhere((r) => r.id == updatedReminder.id);
    if (index != -1) {
      _reminders[index] = updatedReminder;
      _saveToPrefs();
      notifyListeners();
    }
  }

  void removeReminder(String id) {
    _reminders.removeWhere((r) => r.id == id);
    _saveToPrefs();
    notifyListeners();
  }

  ReminderModel? getReminderById(String id) {
    try {
      return _reminders.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}
