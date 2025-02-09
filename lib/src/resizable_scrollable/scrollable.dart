import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../flutter_utils.dart';

export 'scrollable_extended.dart';

const _iconSize = 20.0;
const _scrollIconPadding = EdgeInsets.zero;

class MultiScrollController {
  MultiScrollController({
    ScrollController? vertical,
    ScrollController? horizontal,
    void Function(double)? setScale,
    this.canScale = false,
  })  : vertical = vertical ?? ScrollController(),
        horizontal = horizontal ?? ScrollController(),
        _setScale = setScale;

  final ScrollController vertical;
  final ScrollController horizontal;
  final void Function(double)? _setScale;
  final bool canScale;
  late BuildContext _context;

  final scaleNotifier = ValueNotifier<double>(1);
  double get scale => scaleNotifier.value;

  final sizeNotifier = ValueNotifier<Size>(const Size(1, 1));
  Size get size => sizeNotifier.value;

  Offset get offset {
    return Offset(
      horizontal.offset,
      vertical.offset,
    );
  }

  Rect? get bounds => globalPaintBounds(_context);

  Offset toCanvasOffset(Offset offset) {
    final _canvasOffset = offset + offset - bounds!.topLeft;
    return _canvasOffset / scale;
  }

  Offset get translateOffset =>
      Offset(size.width / 2, size.height / 2) * (scale - 1);

  void onDrag(Offset delta) {
    if (delta.dx != 0) {
      final hp = horizontal.position;
      final dx = (horizontal.offset - delta.dx).clamp(0.0, hp.maxScrollExtent);
      horizontal.jumpTo(dx);
    }

    if (delta.dy != 0) {
      final vp = vertical.position;
      final dy = (vertical.offset - delta.dy).clamp(0.0, vp.maxScrollExtent);
      vertical.jumpTo(dy);
    }
  }

  void onScale(double newScale) {
    if (!canScale) {
      return;
    }
    scaleNotifier.value = newScale.clamp(0.4, 2.5);
    _setScale?.call(scale);
    notifyAll();
  }

  void setSize(Size newSize) {
    if (newSize != size) {
      sizeNotifier.value = newSize;
      notifyAll();
    }
  }

  void notifyAll() {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      if (horizontal.hasClients) {
        final multiplerH = horizontal.offset <= 0.01 ? 1 : -1;
        horizontal.jumpTo(horizontal.offset + multiplerH * 0.0001);
      }
      if (vertical.hasClients) {
        final multiplerV = vertical.offset <= 0.01 ? 1 : -1;
        vertical.jumpTo(vertical.offset + multiplerV * 0.0001);
      }
    });
  }

  Widget sizer() {
    return _DummySizer(onBuild: setSize);
  }

  void dispose() {
    vertical.dispose();
    horizontal.dispose();
  }
}

class SingleScrollable extends StatelessWidget {
  final Widget? child;
  final Widget Function(BuildContext, ScrollController)? builder;
  final Axis scrollDirection;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;

  const SingleScrollable({
    Key? key,
    this.child,
    this.builder,
    this.scrollDirection = Axis.vertical,
    this.alignment,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiScrollable(
      builder: (context, controller) {
        final _controller = scrollDirection == Axis.vertical
            ? controller.vertical
            : controller.horizontal;
        if (child != null) {
          Widget _child = SingleChildScrollView(
            scrollDirection: scrollDirection,
            controller: _controller,
            child: child,
          );
          if (alignment != null) {
            _child = Align(
              alignment: alignment!,
              child: _child,
            );
          }
          if (padding != null) {
            _child = Padding(
              padding: padding!,
              child: _child,
            );
          }
          return _child;
        } else {
          return builder!(context, _controller);
        }
      },
    );
  }
}

class MultiScrollable extends StatefulWidget {
  const MultiScrollable({
    this.builder,
    Key? key,
    this.controller,
    this.routeObserver,
  }) : super(key: key);
  final Widget Function(
    BuildContext context,
    MultiScrollController controller,
  )? builder;
  final MultiScrollController? controller;
  final RouteObserver? routeObserver;

  @override
  _MultiScrollableState createState() => _MultiScrollableState();
}

class _MultiScrollableState extends State<MultiScrollable> with RouteAware {
  late final MultiScrollController controller;
  double? innerWidth;
  double? innerHeight;
  RouteObserver? _routeObserver;

  @override
  void initState() {
    super.initState();
    _initController();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyAll();
    });
  }

  @override
  void didUpdateWidget(covariant MultiScrollable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _initController();
    }
  }

  void _initController() {
    controller = widget.controller ?? MultiScrollController();
    controller._context = context;
    controller.notifyAll();
  }

  void _notifyAll() {
    setState(() {
      controller.notifyAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.builder!(context, controller);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                      if (innerWidth != box.maxWidth ||
                          innerHeight != box.maxHeight) {
                        setState(() {
                          innerWidth = box.maxWidth;
                          innerHeight = box.maxHeight;
                        });
                      }
                    });
                    return child;
                  },
                ),
              ),
              ButtonScrollbar(
                controller: controller.vertical,
                horizontal: false,
                maxSize: innerHeight,
              ),
            ],
          ),
        ),
        ButtonScrollbar(
          controller: controller.horizontal,
          horizontal: true,
          maxSize: innerWidth,
        ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeObserver = widget.routeObserver;
    _routeObserver?.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    controller.dispose();
    _routeObserver?.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _notifyAll();
  }
}

class ButtonScrollbar extends HookWidget {
  const ButtonScrollbar({
    Key? key,
    required this.controller,
    required this.maxSize,
    required this.horizontal,
  }) : super(key: key);

  final ScrollController controller;
  final bool horizontal;
  final double? maxSize;

  void onPressedScrollButtonStart() {
    controller.jumpTo(max(controller.offset - 20, 0));
  }

  void onPressedScrollButtonEnd() {
    controller.jumpTo(
      min(controller.offset + 20, controller.position.maxScrollExtent),
    );
  }

  @override
  Widget build(BuildContext context) {
    useListenable(controller);
    final isPressedButton = useState(false);
    if (!controller.hasClients ||
        !controller.position.hasViewportDimension ||
        controller.position.viewportDimension < maxSize! ||
        controller.position.maxScrollExtent == 0) {
      return const SizedBox(width: 0, height: 0);
    }

    Future onLongPressStartForward(LongPressStartDetails _) async {
      isPressedButton.value = true;
      while (isPressedButton.value &&
          controller.offset < controller.position.maxScrollExtent) {
        await controller.animateTo(
          min(controller.offset + 50, controller.position.maxScrollExtent),
          duration: const Duration(milliseconds: 150),
          curve: Curves.linear,
        );
      }
    }

    Future onLongPressStartBackward(LongPressStartDetails _) async {
      isPressedButton.value = true;
      while (isPressedButton.value && controller.offset > 0) {
        await controller.animateTo(
          max(controller.offset - 50, 0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.linear,
        );
      }
    }

    final children = [
      _ScrollbarButton(
        isStart: true,
        horizontal: horizontal,
        onLongPressStart: onLongPressStartBackward,
        onLongPressEnd: (details) => isPressedButton.value = false,
        onPressed: onPressedScrollButtonStart,
      ),
      Expanded(
        child: MultiScrollbar(
          controller: controller,
          horizontal: horizontal,
        ),
      ),
      _ScrollbarButton(
        isStart: false,
        horizontal: horizontal,
        onLongPressStart: onLongPressStartForward,
        onLongPressEnd: (details) => isPressedButton.value = false,
        onPressed: onPressedScrollButtonEnd,
      )
    ];

    final _size = horizontal
        ? Size(maxSize ?? double.infinity, _iconSize)
        : Size(_iconSize, maxSize ?? double.infinity);

    return ConstrainedBox(
      constraints: BoxConstraints.loose(_size),
      child: Flex(
        direction: horizontal ? Axis.horizontal : Axis.vertical,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: children,
      ),
    );
  }
}

class _ScrollbarButton extends StatelessWidget {
  final void Function(LongPressStartDetails) onLongPressStart;
  final void Function(LongPressEndDetails) onLongPressEnd;
  final void Function() onPressed;
  final bool horizontal;
  final bool isStart;

  const _ScrollbarButton({
    Key? key,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.onPressed,
    required this.horizontal,
    required this.isStart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: onLongPressStart,
      onLongPressEnd: onLongPressEnd,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: _iconSize,
          maxWidth: _iconSize,
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: _scrollIconPadding,
          ),
          child: Icon(
            isStart
                ? (horizontal ? Icons.arrow_left : Icons.arrow_drop_up)
                : (horizontal ? Icons.arrow_right : Icons.arrow_drop_down),
            size: _iconSize,
          ),
        ),
      ),
    );
  }
}

class MultiScrollbar extends HookWidget {
  const MultiScrollbar({
    required this.controller,
    this.horizontal = false,
    Key? key,
  }) : super(key: key);
  final ScrollController controller;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final position = controller.position;
    final offset = controller.offset;
    final scrollExtent = position.maxScrollExtent + position.viewportDimension;

    return LayoutBuilder(
      builder: (context, box) {
        final maxSize = horizontal ? box.maxWidth : box.maxHeight;
        final handleSize = maxSize * position.viewportDimension / scrollExtent;
        final rate = (maxSize - handleSize) / position.maxScrollExtent;
        final top = rate * offset;

        return Flex(
          direction: horizontal ? Axis.horizontal : Axis.vertical,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (horizontal) SizedBox(width: top) else SizedBox(height: top),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontal ? 0 : 3,
                vertical: horizontal ? 3 : 0,
              ),
              child: _ScrollHandle(
                horizontal: horizontal,
                handleSize: handleSize,
                controller: controller,
                rate: rate,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScrollHandle extends HookWidget {
  const _ScrollHandle({
    Key? key,
    required this.horizontal,
    required this.handleSize,
    required this.controller,
    required this.rate,
  }) : super(key: key);

  final bool horizontal;
  final double handleSize;
  final ScrollController controller;
  final double rate;

  @override
  Widget build(BuildContext context) {
    final position = controller.position;
    final hovering = useState(false);
    final dragging = useState(false);
    final baseColor = Theme.of(context).colorScheme.onSurface;

    return MouseRegion(
      onEnter: (_) => hovering.value = true,
      onExit: (_) => hovering.value = false,
      child: GestureDetector(
        dragStartBehavior: DragStartBehavior.down,
        onPanDown: (_) => dragging.value = true,
        onPanEnd: (_) => dragging.value = false,
        onPanUpdate: (DragUpdateDetails p) {
          final _delta = horizontal ? p.delta.dx : p.delta.dy;
          final _offset = (controller.offset + _delta / rate)
              .clamp(0.0, position.maxScrollExtent);
          controller.jumpTo(_offset);
        },
        child: SizedBox(
          height: horizontal ? double.infinity : handleSize,
          width: horizontal ? handleSize : double.infinity,
          child: Container(
            color: hovering.value || dragging.value
                ? baseColor.withOpacity(0.17)
                : baseColor.withOpacity(0.12),
          ),
        ),
      ),
    );
  }
}

class _DummySizer extends SingleChildRenderObjectWidget {
  final Function(Size) onBuild;

  const _DummySizer({Key? key, required this.onBuild}) : super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _TRenderBox(onBuild: onBuild);
  }
}

class _TRenderBox extends RenderBox {
  _TRenderBox({this.onBuild});

  final Function(Size)? onBuild;

  @override
  void paint(PaintingContext context, Offset offset) {
    final _p = parent;
    if (_p is RenderFlex && _p.hasSize) {
      onBuild!(_p.size);
    }
    super.paint(context, offset);
  }

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = constraints.smallest;
  }
}
