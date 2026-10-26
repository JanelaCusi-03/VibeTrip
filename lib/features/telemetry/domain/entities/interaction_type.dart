/// Canal de captura (ENUM `capture_channel`).
enum CaptureChannel {
  explicit('explicit'),
  implicit('implicit');

  const CaptureChannel(this.wireName);

  final String wireName;
}

/// Tipo de interacción (ENUM `interaction_type`) con su peso base
/// (Entregable 1 §1.3). El peso de `dwell` se calcula con la fórmula de
/// saturación exponencial, por eso su peso base es 0.
enum InteractionType {
  swipeLike('swipe_like', CaptureChannel.explicit, 1.0),
  swipeDislike('swipe_dislike', CaptureChannel.explicit, -1.0),
  swipeSuperlike('swipe_superlike', CaptureChannel.explicit, 1.0),
  abChoice('ab_choice', CaptureChannel.explicit, 0.5),
  impressionSkip('impression_skip', CaptureChannel.implicit, -0.05),
  viewDetail('view_detail', CaptureChannel.implicit, 0.25),
  dwell('dwell', CaptureChannel.implicit, 0),
  photoExpand('photo_expand', CaptureChannel.implicit, 0.35),
  directionsClick('directions_click', CaptureChannel.implicit, 0.90),
  share('share', CaptureChannel.implicit, 0.80),
  favoriteAdd('favorite_add', CaptureChannel.explicit, 1.0),
  favoriteRemove('favorite_remove', CaptureChannel.explicit, -0.50),
  discard('discard', CaptureChannel.explicit, -1.0);

  const InteractionType(this.wireName, this.channel, this.baseSignalWeight);

  final String wireName;
  final CaptureChannel channel;
  final double baseSignalWeight;

  bool get isImplicit => channel == CaptureChannel.implicit;

  static InteractionType fromWireName(String wireName) =>
      values.firstWhere((type) => type.wireName == wireName);
}
