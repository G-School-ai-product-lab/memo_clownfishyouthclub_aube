class GuideProgress {
  final bool firstMemoCreated;
  final bool aiClassificationChecked;
  final bool naturalSearchUsed;
  final bool linkSummaryChecked;
  final bool guideCompleted;

  const GuideProgress({
    this.firstMemoCreated = false,
    this.aiClassificationChecked = false,
    this.naturalSearchUsed = false,
    this.linkSummaryChecked = false,
    this.guideCompleted = false,
  });

  int get completedCount {
    int count = 0;
    if (firstMemoCreated) count++;
    if (aiClassificationChecked) count++;
    if (naturalSearchUsed) count++;
    if (linkSummaryChecked) count++;
    return count;
  }

  int get totalCount => 4;

  bool get isAllCompleted => completedCount == totalCount;

  GuideProgress copyWith({
    bool? firstMemoCreated,
    bool? aiClassificationChecked,
    bool? naturalSearchUsed,
    bool? linkSummaryChecked,
    bool? guideCompleted,
  }) {
    return GuideProgress(
      firstMemoCreated: firstMemoCreated ?? this.firstMemoCreated,
      aiClassificationChecked: aiClassificationChecked ?? this.aiClassificationChecked,
      naturalSearchUsed: naturalSearchUsed ?? this.naturalSearchUsed,
      linkSummaryChecked: linkSummaryChecked ?? this.linkSummaryChecked,
      guideCompleted: guideCompleted ?? this.guideCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstMemoCreated': firstMemoCreated,
      'aiClassificationChecked': aiClassificationChecked,
      'naturalSearchUsed': naturalSearchUsed,
      'linkSummaryChecked': linkSummaryChecked,
      'guideCompleted': guideCompleted,
    };
  }

  factory GuideProgress.fromJson(Map<String, dynamic> json) {
    return GuideProgress(
      firstMemoCreated: json['firstMemoCreated'] as bool? ?? false,
      aiClassificationChecked: json['aiClassificationChecked'] as bool? ?? false,
      naturalSearchUsed: json['naturalSearchUsed'] as bool? ?? false,
      linkSummaryChecked: json['linkSummaryChecked'] as bool? ?? false,
      guideCompleted: json['guideCompleted'] as bool? ?? false,
    );
  }
}
