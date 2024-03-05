import 'package:flutter/material.dart';

class Val<T> {
  final T inner;

  const Val(this.inner);
}

class PortalNotifier {
  final ValueNotifier<bool> showNotifier;
  const PortalNotifier({
    required this.showNotifier,
  });

  void hide() {
    showNotifier.value = false;
  }

  void show() {
    showNotifier.value = true;
  }

  void toggle() {
    showNotifier.value = !showNotifier.value;
  }
}

typedef PortalBundler = Widget Function({
  required Widget child,
  required Widget portal,
  required bool show,
});

@immutable
class PortalParams {
  final void Function()? onTapOutside;
  final Color? backgroundColor;
  final Alignment? childAnchor;
  final Alignment? portalAnchor;
  final Alignment? alignment;
  final Widget Function(BuildContext, Widget)? portalWrapper;
  final double screenMargin;

  const PortalParams({
    this.onTapOutside,
    this.backgroundColor,
    this.childAnchor,
    this.portalAnchor,
    this.alignment,
    this.portalWrapper,
    this.screenMargin = 0,
  }) : assert((portalAnchor == null) == (childAnchor == null));

  PortalParams copyWith({
    Val<void Function()?>? onTapOutside,
    Val<Color?>? backgroundColor,
    Val<Alignment?>? childAnchor,
    Val<Alignment?>? portalAnchor,
    Val<Alignment?>? alignment,
    Val<Widget Function(BuildContext, Widget)?>? portalWrapper,
    double? screenMargin,
  }) {
    return PortalParams(
      onTapOutside:
          onTapOutside != null ? onTapOutside.inner : this.onTapOutside,
      backgroundColor: backgroundColor != null
          ? backgroundColor.inner
          : this.backgroundColor,
      childAnchor: childAnchor != null ? childAnchor.inner : this.childAnchor,
      portalAnchor:
          portalAnchor != null ? portalAnchor.inner : this.portalAnchor,
      alignment: alignment != null ? alignment.inner : this.alignment,
      portalWrapper:
          portalWrapper != null ? portalWrapper.inner : this.portalWrapper,
      screenMargin: screenMargin ?? this.screenMargin,
    );
  }

  @override
  String toString() {
    return 'PortalParams(onTapOutside: $onTapOutside, backgroundColor: '
        '$backgroundColor, childAnchor: $childAnchor, '
        'portalAnchor: $portalAnchor, alignment: $alignment, screenMargin: '
        '$screenMargin, portalWrapper: $portalWrapper)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PortalParams &&
        other.onTapOutside == onTapOutside &&
        other.backgroundColor == backgroundColor &&
        other.childAnchor == childAnchor &&
        other.portalAnchor == portalAnchor &&
        other.alignment == alignment &&
        other.screenMargin == screenMargin &&
        other.portalWrapper == portalWrapper;
  }

  @override
  int get hashCode {
    return Object.hash(
      onTapOutside,
      backgroundColor,
      childAnchor,
      portalAnchor,
      alignment,
      screenMargin,
      portalWrapper,
    );
  }
}
