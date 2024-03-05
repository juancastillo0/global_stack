import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../flutter_utils.dart';
import 'global_stack.dart';
import 'portal_utils.dart';
import 'portal_wrapper.dart';

enum OverlayGesture {
  tap,
  secondaryTap,
}

class CustomOverlayButton extends HookWidget {
  final Widget Function(PortalNotifier) portalBuilder;
  final Widget child;
  final PortalBundler? builder;
  final PortalParams params;
  final OverlayGesture gesture;

  const CustomOverlayButton({
    required this.portalBuilder,
    required this.child,
    this.params = const PortalParams(),
    this.builder,
    this.gesture = OverlayGesture.tap,
    Key? key,
  }) : super(key: key);

  const CustomOverlayButton.stack({
    required this.portalBuilder,
    required this.child,
    this.params = const PortalParams(),
    this.gesture = OverlayGesture.tap,
    Key? key,
  })  : builder = StackPortal.make,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final show = useState(false);

    final _portalNotifier = useMemoized(
      () => PortalNotifier(
        showNotifier: show,
      ),
    );

    final _portalKey = useMemoized(() => GlobalKey());
    final _childKey = useMemoized(() => GlobalKey());
    final toggle = _portalNotifier.toggle;

    final Widget _inner;
    switch (gesture) {
      case OverlayGesture.tap:
        _inner = TextButton(
          onPressed: toggle,
          child: child,
        );
        break;
      case OverlayGesture.secondaryTap:
        _inner = GestureDetector(
          onSecondaryTap: toggle,
          child: child,
        );
    }

    if (builder != null) {
      return builder!(
        show: show.value,
        portal: Inherited(
          data: _portalNotifier,
          child: makePositioned(
            portalBuilder: (context) => portalBuilder(_portalNotifier),
            childKey: _childKey,
            portalKey: _portalKey,
            params: params.copyWith(
              onTapOutside: Val(() {
                toggle();
                params.onTapOutside?.call();
              }),
            ),
          ),
        ),
        child: KeyedSubtree(
          key: _childKey,
          child: _inner,
        ),
      );
    }

    return CustomOverlay(
      show: show.value,
      portal: portalBuilder(_portalNotifier),
      params: params,
      child: _inner,
    );
  }
}

class StackOverlay extends HookWidget {
  final Widget Function(BuildContext) portalBuilder;
  final Widget child;
  final PortalParams params;
  final bool show;

  const StackOverlay({
    required this.portalBuilder,
    required this.child,
    required this.show,
    this.params = const PortalParams(),
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _portalKey = useMemoized(() => GlobalKey());
    final _childKey = useMemoized(() => GlobalKey());

    return StackPortal(
      show: show,
      portal: makePositioned(
        portalBuilder: portalBuilder,
        childKey: _childKey,
        portalKey: _portalKey,
        params: params,
      ),
      child: KeyedSubtree(
        key: _childKey,
        child: child,
      ),
    );
  }
}

class CustomOverlay extends HookWidget {
  final bool show;
  final Widget portal;
  final Widget child;
  final PortalParams params;

  const CustomOverlay({
    required this.show,
    required this.portal,
    required this.child,
    this.params = const PortalParams(),
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final overlay = Overlay.maybeOf(context);

    final _keyPortal = useMemoized(() => GlobalKey());
    final _keyChild = useMemoized(() => GlobalKey());
    final _portalRef = useMemoized(() => _Ref(portal));
    _portalRef.widget = portal;

    final entry = useMemoized(
      () => OverlayEntry(
        builder: (context) => makePositioned(
          childKey: _keyChild,
          portalKey: _keyPortal,
          portalBuilder: (context) => _portalRef.widget,
          params: params,
        ),
      ),
      [params],
    );

    void _tryRebuildEntry() {
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        if (show && entry.mounted) {
          entry.markNeedsBuild();
        }
      });
    }

    useEffect(
      () {
        if (show && overlay != null) {
          SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
            if (show) {
              overlay.insert(entry);
              _tryRebuildEntry();
            }
          });
          return () {
            entry.remove();
          };
        }
        return null;
      },
      [show, overlay, entry],
    );

    useEffect(
      () {
        _tryRebuildEntry();
        return null;
      },
      [portal],
    );

    return KeyedSubtree(key: _keyChild, child: child);
  }
}

class _Ref {
  Widget widget;
  _Ref(this.widget);
}
