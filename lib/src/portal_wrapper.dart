import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../flutter_utils.dart';
import 'portal_utils.dart';

Widget makePositioned({
  required GlobalKey childKey,
  required GlobalKey portalKey,
  required Widget Function(BuildContext) portalBuilder,
  PortalParams params = const PortalParams(),
}) {
  return StatefulBuilder(
    builder: (context, setState) {
      final onTapOutside = params.onTapOutside;

      Widget widget = GestureDetector(
        onTap: onTapOutside == null ? null : () {},
        child: KeyedSubtree(
          key: portalKey,
          child: params.portalWrapper != null
              ? params.portalWrapper!(context, portalBuilder(context))
              : portalBuilder(context),
        ),
      );

      final childAnchor = params.childAnchor;
      final portalAnchor = params.portalAnchor;
      if (childAnchor != null && portalAnchor != null) {
        final mq = MediaQuery.of(context);
        final bounds = globalPaintBounds(childKey.currentContext) ?? Rect.zero;
        final boundsPortal =
            globalPaintBounds(portalKey.currentContext) ?? Rect.zero;

        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          final _new = globalPaintBounds(portalKey.currentContext) ?? Rect.zero;
          final _inter = _new.intersect(boundsPortal);
          if (_inter.width < _new.width * 0.99 ||
              _inter.height < _new.height * 0.99) {
            setState(() {});
          }
        });

        final pos = childAnchor.withinRect(bounds) -
            portalAnchor.alongSize(boundsPortal.size);
        final margin = params.screenMargin;
        widget = Positioned(
          top: pos.dy.clamp(
            margin,
            mq.size.height - boundsPortal.height - margin,
          ),
          left: pos.dx.clamp(
            margin,
            mq.size.width - boundsPortal.width - margin,
          ),
          // bottom: mq.size.height - bounds.top,
          // left: bounds.topCenter.dx - boundsPortal.width / 2,
          child: Visibility(
            visible: globalPaintBounds(portalKey.currentContext) != null,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: widget,
          ),
        );
      } else if (params.alignment != null) {
        widget = Align(
          alignment: params.alignment!,
          child: widget,
        );
      }

      if (onTapOutside != null) {
        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: onTapOutside,
              child: DecoratedBox(
                // constraints: const BoxConstraints.expand(),
                decoration: BoxDecoration(
                  color: params.backgroundColor ?? Colors.black26,
                ),
              ),
            ),
            widget,
          ],
        );
      }

      return widget;
    },
  );
}

Map<Type, Action<Intent>> _defaultPortalActions(BuildContext context) {
  return {
    DismissIntent: CallbackAction(
      onInvoke: (intent) {
        final notifier = Inherited.of<PortalNotifier>(context);
        notifier.hide();
        return null;
      },
    )
  };
}

Widget Function(BuildContext, Widget) makeDefaultPortalWrapper({
  EdgeInsetsGeometry? padding,
}) {
  Widget wrapper(BuildContext context, Widget child) {
    return DefualtPortalWrapper(
      padding: padding,
      child: child,
    );
  }

  return wrapper;
}

Widget defaultPortalWrapper(BuildContext context, Widget child) {
  return DefualtPortalWrapper(child: child);
}

class DefualtPortalWrapper extends HookWidget {
  const DefualtPortalWrapper({
    Key? key,
    this.padding,
    required this.child,
  }) : super(key: key);
  final EdgeInsetsGeometry? padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // final notifier = Inherited.of<PortalNotifier>(context);
    final focusNode = useFocusNode();

    final _prevFocus = Focus.maybeOf(context);
    useEffect(() {
      focusNode.requestFocus();
      return () {
        if (_prevFocus != null && _prevFocus.canRequestFocus) {
          _prevFocus.requestFocus();
        }
      };
    }, [focusNode]);

    return FocusTraversalGroup(
      child: FocusableActionDetector(
        autofocus: true,
        focusNode: focusNode,
        actions: _defaultPortalActions(context),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Card(
              elevation: 5,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
              ),
              margin: const EdgeInsets.all(4.0),
              child: Padding(
                padding: padding ??
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: child,
              ),
            ),
            // Positioned(
            //   top: -2,
            //   right: -2,
            //   child: Container(
            //     decoration: BoxDecoration(
            //       color: Theme.of(context).scaffoldBackgroundColor,
            //       shape: BoxShape.circle,
            //     ),
            //     padding: const EdgeInsets.all(4),
            //     child: SmallIconButton(
            //       onPressed: notifier.hide,
            //       child: const Icon(Icons.close),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
