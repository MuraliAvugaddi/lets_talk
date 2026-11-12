import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/apis/api_endpoint.dart';


/// Admin's special-class switches — updated LIVE over the socket (no refresh needed):
///   🌐 rain     → offline students have their class ONLINE (reason in `onlineReason`)
///   🎙 assembly → special class: everyone joins one live class at the time the admin picked
class ClassModeController extends GetxController {
  static ClassModeController get to => Get.isRegistered<ClassModeController>()
      ? Get.find<ClassModeController>()
      : Get.put(ClassModeController(), permanent: true);

  final Rxn<Map<String, dynamic>> rain = Rxn<Map<String, dynamic>>();
  final Rxn<Map<String, dynamic>> assembly = Rxn<Map<String, dynamic>>();

  bool get rainOn => rain.value?['active'] == true;
  bool get assemblyOn => assembly.value?['active'] == true;
  String get onlineReason => (rain.value?['note'] ?? '').toString();

  /// Stages the admin moved online today (empty = ALL stages)
  List<String> get rainStages {
    final st = rain.value?['stages'];
    return st is List ? st.map((e) => e.toString().toLowerCase()).toList() : const [];
  }

  /// Is THIS stage ("stage1") online today?
  bool rainCovers(String stage) {
    if (!rainOn) return false;
    final list = rainStages;
    return list.isEmpty || list.contains(stage.toLowerCase().replaceAll(' ', ''));
  }

  /// Any of my open stages online today? access = userData['englishAccess'] / ['hindiAccess']
  bool rainCoversAny(dynamic access) {
    if (!rainOn) return false;
    if (rainStages.isEmpty) return true;
    if (access is! Map) return false;
    return access.entries.any((e) => e.value == true && rainCovers(e.key.toString()));
  }

  /// "Stage 1, Stage 3" (for the banner); empty when all stages
  String get rainStagesText => rainStages.map((s) => s.replaceAll('stage', 'Stage ')).join(', ');
  String get assemblyTitle {
    final t = (assembly.value?['title'] ?? '').toString().trim();
    return t.isEmpty ? 'Surendra Sir Special Class' : t;
  }

  String get assemblyTime => (assembly.value?['startTime'] ?? '').toString();

  dynamic _socket; // the socket we attached to (AuthController creates it)

  @override
  void onInit() {
    super.onInit();
    attachSocket();
  }

  void _apply(dynamic data) {
    if (data is! Map) return;
    rain.value = data['rain'] is Map ? Map<String, dynamic>.from(data['rain']) : null;
    assembly.value = data['assembly'] is Map ? Map<String, dynamic>.from(data['assembly']) : null;
  }

  void _onUpdate(dynamic data) {
    // the new state comes WITH the event → instant, no extra request
    if (data is Map && data.containsKey('rain')) {
      _apply(data);
    } else {
      fetch();
    }
  }

  /// Listen to admin changes on the app's existing socket (safe to call many times).
  void attachSocket() {
    if (!Get.isRegistered<AuthController>()) return;
    final s = Get.find<AuthController>().socket;
    if (s == null || identical(s, _socket)) return;
    try {
      _socket?.off('class_mode_update', _onUpdate);
    } catch (_) {}
    _socket = s;
    s.on('class_mode_update', _onUpdate);
  }

  Future<void> fetch() async {
    attachSocket(); // the socket may have been re-created after login
    try {
      final res = await http.get(Uri.parse(ApiEndpoints.classMode)).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) _apply(jsonDecode(res.body));
    } catch (e) {
      debugPrint('Class mode fetch error: $e');
    }
  }
}
