import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/guide_progress.dart';

class GuideService {
  static const String _keyGuideProgress = 'guide_progress';
  static const String _keyGuideDismissed = 'guide_dismissed';

  Future<GuideProgress> getGuideProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyGuideProgress);

    if (jsonString == null) {
      return const GuideProgress();
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return GuideProgress.fromJson(json);
    } catch (e) {
      return const GuideProgress();
    }
  }

  Future<void> saveGuideProgress(GuideProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(progress.toJson());
    await prefs.setString(_keyGuideProgress, jsonString);
  }

  Future<void> markFirstMemoCreated() async {
    final progress = await getGuideProgress();
    final updated = progress.copyWith(firstMemoCreated: true);
    await saveGuideProgress(updated);
  }

  Future<void> markAiClassificationChecked() async {
    final progress = await getGuideProgress();
    final updated = progress.copyWith(aiClassificationChecked: true);
    await saveGuideProgress(updated);
  }

  Future<void> markNaturalSearchUsed() async {
    final progress = await getGuideProgress();
    final updated = progress.copyWith(naturalSearchUsed: true);
    await saveGuideProgress(updated);
  }

  Future<void> markLinkSummaryChecked() async {
    final progress = await getGuideProgress();
    final updated = progress.copyWith(linkSummaryChecked: true);
    await saveGuideProgress(updated);
  }

  Future<void> completeGuide() async {
    final progress = await getGuideProgress();
    final updated = progress.copyWith(guideCompleted: true);
    await saveGuideProgress(updated);
  }

  Future<bool> shouldShowGuide() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool(_keyGuideDismissed) ?? false;

    if (dismissed) return false;

    final progress = await getGuideProgress();
    return !progress.guideCompleted && !progress.isAllCompleted;
  }

  Future<void> dismissGuide() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGuideDismissed, true);
  }

  Future<void> resetGuide() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyGuideProgress);
    await prefs.remove(_keyGuideDismissed);
  }
}
