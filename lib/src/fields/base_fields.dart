import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'error_overlay.dart';
import 'formatters.dart';

export 'error_overlay.dart';

abstract class OnChange<T extends Object> {
  const OnChange._();

  const factory OnChange.req(void Function(T) _onChange) = OnChangeRequired;
  const factory OnChange.opt(void Function(T?) _onChange) = OnChangeOptional;

  void onChange(T? value);

  bool get isRequired => this is OnChangeRequired;

  void call(T? value) => onChange(value);
}

class OnChangeRequired<T extends Object> extends OnChange<T> {
  final void Function(T) _onChange;
  const OnChangeRequired(this._onChange) : super._();

  @override
  void onChange(T? value) {
    if (value != null) {
      _onChange(value);
    }
  }
}

class OnChangeOptional<T extends Object> extends OnChange<T> {
  final void Function(T?) _onChange;
  const OnChangeOptional(this._onChange) : super._();

  @override
  void onChange(T? value) {
    _onChange(value);
  }
}

class DoubleInput extends HookWidget {
  final String label;
  final void Function(double?) onChanged;
  final double? value;

  const DoubleInput({
    Key? key,
    required this.label,
    required this.onChanged,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final input = useTextInput<double>(
      value,
      onChanged,
      doubleStringInput,
    );

    return TextField(
      controller: input.controller,
      decoration: InputDecoration(
        labelText: label,
        errorText: input.errorIfTouchedNotEmpty,
      ),
      onChanged: input.onChangedString,
      inputFormatters: [Formatters.onlyDigitsOrDecimal],
      focusNode: input.focusNode,
      keyboardType: TextInputType.number,
    );
  }
}

class IntInput extends HookWidget {
  final String label;
  final void Function(int?) onChanged;
  final int? value;
  final String? error;

  const IntInput({
    Key? key,
    required this.label,
    required this.onChanged,
    required this.value,
    this.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final input = useTextInput<int>(
      value,
      onChanged,
      intStringInput,
    );

    const _size = 20.0;
    final _buttonStyle = TextButton.styleFrom(
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      fixedSize: const Size(_size, _size),
      minimumSize: const Size(_size, _size),
    );
    final _error = error ?? input.errorIfTouchedNotEmpty;

    return ErrorOverlay(
      error: _error,
      focusNode: input.focusNode,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: input.controller,
              decoration: InputDecoration(
                labelText: label,
                errorText: error ?? input.errorIfTouchedNotEmpty,
              ),
              onChanged: input.onChangedString,
              inputFormatters: [Formatters.onlyDigits],
              focusNode: input.focusNode,
              keyboardType: TextInputType.number,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: value == null
                    ? null
                    : () {
                        onChanged(value! + 1);
                      },
                style: _buttonStyle,
                child: const Icon(Icons.arrow_drop_up, size: _size - 2),
              ),
              TextButton(
                onPressed: value == null
                    ? null
                    : () {
                        onChanged(value! - 1);
                      },
                style: _buttonStyle,
                child: const Icon(Icons.arrow_drop_down, size: _size - 2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final doubleStringInput = StringInputSerializer<double>(
  double.tryParse,
  (v) {
    final str = v.toString();
    return str.endsWith('.0') ? str.substring(0, str.length - 2) : str;
  },
);

String objectToString(Object v) => v.toString();

const intStringInput = StringInputSerializer<int>(
  int.tryParse,
  objectToString,
);

class StringInputSerializer<T> {
  final T? Function(String) fromString;
  final String Function(T) asString;
  final String? Function(String, T?)? validate;

  static String? defaultValidate(String s, Object? v) => v == null ? '' : null;

  const StringInputSerializer(
    this.fromString,
    this.asString, {
    this.validate = defaultValidate,
  });
}

TextInputParams useTextInput<T>(
  T? value,
  void Function(T?) onChanged,
  StringInputSerializer<T> serializer,
) {
  final controller = useTextEditingController();
  final focusNode = useFocusNode();
  final error = useState<String?>(null);
  final wasTouched = useState(false);
  final wasFocused = useState(false);
  final wasEdited = useState(false);

  useEffect(
    () {
      if (value == null) {
        controller.value = controller.value.copyWith(text: '');
      } else if (serializer.fromString(controller.text) != value) {
        error.value = null;
        controller.value = controller.value.copyWith(
          text: serializer.asString(value),
        );
      }
      return null;
    },
    [serializer, value],
  );

  final onChangedString = useMemoized(() {
    void _onControllerChange(String newString) {
      wasEdited.value = true;
      final newValue = serializer.fromString(newString);
      final newError = serializer.validate?.call(newString, newValue);

      if (newValue != null && newError == null) {
        if (value != newValue) {
          onChanged(newValue);
        }
        error.value = null;
      } else if (newString.isEmpty) {
        if (value != newValue) {
          onChanged(null);
        }
      } else {
        error.value = newError ?? '';
      }
    }

    return _onControllerChange;
  }, [serializer, value, onChanged]);

  useEffect(
    () {
      if (!wasFocused.value) {
        void _c() {
          if (focusNode.hasPrimaryFocus) {
            wasFocused.value = true;
          }
        }

        focusNode.addListener(_c);
        return () {
          focusNode.removeListener(_c);
        };
      }
      return null;
    },
    [wasFocused.value],
  );

  useValueChanged<bool, void>(focusNode.hasPrimaryFocus, (prev, _) {
    if (prev && !focusNode.hasPrimaryFocus) {
      wasTouched.value = true;
    }
  });

  return TextInputParams(
    controller: controller,
    focusNode: focusNode,
    error: error.value,
    wasTouched: wasTouched.value,
    wasFocused: wasFocused.value,
    wasEdited: wasEdited.value,
    onChangedString: onChangedString,
  );
}

class TextInputParams {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? error;
  final bool wasTouched;
  final bool wasFocused;
  final bool wasEdited;
  final void Function(String) onChangedString;

  const TextInputParams({
    required this.controller,
    required this.focusNode,
    required this.error,
    required this.wasTouched,
    required this.wasFocused,
    required this.wasEdited,
    required this.onChangedString,
  });

  String? get errorIfTouched => wasTouched ? error : null;
  String? get errorIfTouchedNotEmpty =>
      wasTouched && controller.text.isNotEmpty ? error : null;

  String? errorIf({
    bool touched = false,
    bool edited = false,
    bool focused = false,
    bool notEmpty = false,
  }) {
    assert(touched || edited || focused || notEmpty);

    final params = [touched, edited, focused, notEmpty];
    final info = [
      wasTouched,
      wasEdited,
      wasFocused,
      controller.text.isNotEmpty
    ];
    for (final i in Iterable<int>.generate(4)) {
      if (params[i] && !info[i]) {
        return null;
      }
    }

    return error;
  }

  String? errorIfOpts(ShowErrorOpts opts) {
    return errorIf(
      edited: opts.edited ?? false,
      focused: opts.focused ?? false,
      notEmpty: opts.notEmpty ?? false,
      touched: opts.touched ?? false,
    );
  }
}

class WrappedTextInput extends StatelessWidget {
  const WrappedTextInput({
    Key? key,
    required this.input,
    this.errorIf = const ShowErrorOpts(),
    this.error,
    this.label,
    this.params = const TextField(),
  }) : super(key: key);

  final TextInputParams input;
  final ShowErrorOpts errorIf;
  final String? error;
  final String? label;
  final TextField params;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: input.controller,
      focusNode: input.focusNode,
      onChanged: (s) {
        input.onChangedString(s);
        params.onChanged?.call(s);
      },
      decoration: (params.decoration ?? const InputDecoration()).copyWith(
        labelText: label,
        errorText: error ?? input.errorIfOpts(errorIf),
      ),
      keyboardType: params.keyboardType,
      textInputAction: params.textInputAction,
      textCapitalization: params.textCapitalization,
      style: params.style,
      strutStyle: params.strutStyle,
      textAlign: params.textAlign,
      textAlignVertical: params.textAlignVertical,
      textDirection: params.textDirection,
      readOnly: params.readOnly,
      contextMenuBuilder: params.contextMenuBuilder,
      showCursor: params.showCursor,
      autofocus: params.autofocus,
      obscuringCharacter: params.obscuringCharacter,
      obscureText: params.obscureText,
      autocorrect: params.autocorrect,
      smartDashesType: params.smartDashesType,
      smartQuotesType: params.smartQuotesType,
      enableSuggestions: params.enableSuggestions,
      maxLines: params.maxLines,
      minLines: params.minLines,
      expands: params.expands,
      maxLength: params.maxLength,
      clipBehavior: params.clipBehavior,
      maxLengthEnforcement: params.maxLengthEnforcement,
      onEditingComplete: params.onEditingComplete,
      onSubmitted: params.onSubmitted,
      onAppPrivateCommand: params.onAppPrivateCommand,
      inputFormatters: params.inputFormatters,
      enabled: params.enabled,
      cursorWidth: params.cursorWidth,
      cursorHeight: params.cursorHeight,
      cursorRadius: params.cursorRadius,
      cursorColor: params.cursorColor,
      selectionHeightStyle: params.selectionHeightStyle,
      selectionWidthStyle: params.selectionWidthStyle,
      keyboardAppearance: params.keyboardAppearance,
      scrollPadding: params.scrollPadding,
      dragStartBehavior: params.dragStartBehavior,
      enableInteractiveSelection: params.enableInteractiveSelection,
      selectionControls: params.selectionControls,
      onTap: params.onTap,
      mouseCursor: params.mouseCursor,
      buildCounter: params.buildCounter,
      scrollController: params.scrollController,
      scrollPhysics: params.scrollPhysics,
      autofillHints: params.autofillHints,
      restorationId: params.restorationId,
      enableIMEPersonalizedLearning: params.enableIMEPersonalizedLearning,
    );
  }
}

class ShowErrorOpts {
  final bool? touched;
  final bool? edited;
  final bool? focused;
  final bool? notEmpty;

  const ShowErrorOpts({
    this.touched,
    this.edited,
    this.focused,
    this.notEmpty,
  });

  ShowErrorOpts copyWith({
    bool? touched,
    bool? edited,
    bool? focused,
    bool? notEmpty,
  }) {
    return ShowErrorOpts(
      touched: touched ?? this.touched,
      edited: edited ?? this.edited,
      focused: focused ?? this.focused,
      notEmpty: notEmpty ?? this.notEmpty,
    );
  }
}
