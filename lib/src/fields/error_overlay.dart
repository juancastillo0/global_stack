import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../custom_overlay.dart';
import '../portal_utils.dart';

class ErrorOverlay extends HookWidget {
  const ErrorOverlay({
    Key? key,
    this.focusNode,
    required this.error,
    required this.child,
  }) : super(key: key);

  final FocusNode? focusNode;
  final String? error;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isHovering = useState(false);
    final ownFocusNode = useFocusNode();
    final _focusNode = focusNode ?? ownFocusNode;

    useListenable(_focusNode);

    final theme = Theme.of(context);
    final inner = focusNode == null
        ? Focus(focusNode: ownFocusNode, child: child)
        : child;

    return CustomOverlay(
      params: const PortalParams(
        portalAnchor: Alignment.topCenter,
        childAnchor: Alignment.bottomCenter,
      ),
      show: error != null && (_focusNode.hasFocus || isHovering.value),
      portal: Builder(
        builder: (context) {
        return Card(
          color: theme.colorScheme.error,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            constraints: const BoxConstraints(maxWidth: 250),
            child: Text(
              error!,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onError,
              ),
            ),
          ),
        );
      }),
      child: MouseRegion(
        onEnter: (_) {
          isHovering.value = true;
        },
        onExit: (_) {
          isHovering.value = false;
        },
        child: inner,
      ),
    );
  }
}
