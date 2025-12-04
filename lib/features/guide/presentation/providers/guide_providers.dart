import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/guide_service.dart';
import '../../domain/entities/guide_progress.dart';

final guideServiceProvider = Provider<GuideService>((ref) {
  return GuideService();
});

final guideProgressProvider = FutureProvider<GuideProgress>((ref) async {
  final service = ref.watch(guideServiceProvider);
  return await service.getGuideProgress();
});

final shouldShowGuideProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(guideServiceProvider);
  return await service.shouldShowGuide();
});

class GuideNotifier extends StateNotifier<GuideProgress> {
  final GuideService _service;

  GuideNotifier(this._service) : super(const GuideProgress()) {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    state = await _service.getGuideProgress();
  }

  Future<void> markFirstMemoCreated() async {
    await _service.markFirstMemoCreated();
    await _loadProgress();
  }

  Future<void> markAiClassificationChecked() async {
    await _service.markAiClassificationChecked();
    await _loadProgress();
  }

  Future<void> markNaturalSearchUsed() async {
    await _service.markNaturalSearchUsed();
    await _loadProgress();
  }

  Future<void> markLinkSummaryChecked() async {
    await _service.markLinkSummaryChecked();
    await _loadProgress();
  }

  Future<void> completeGuide() async {
    await _service.completeGuide();
    await _loadProgress();
  }

  Future<void> dismissGuide() async {
    await _service.dismissGuide();
  }
}

final guideNotifierProvider = StateNotifierProvider<GuideNotifier, GuideProgress>((ref) {
  final service = ref.watch(guideServiceProvider);
  return GuideNotifier(service);
});
