import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:stack_portal/fields.dart';
import 'package:stack_portal/stack_portal.dart';

PortalParams get defaultPortalParams => const PortalParams(
      childAnchor: Alignment.bottomCenter,
      portalAnchor: Alignment.topCenter,
      portalWrapper: defaultPortalWrapper,
    );

enum DurationRangeType {
  minutes,
  hours,
  days,
}

const maxMillisRange = {
  DurationRangeType.days: 1000 * 60 * 60 * 24 * 45,
  DurationRangeType.hours: 1000 * 60 * 60 * 24 * 2,
  DurationRangeType.minutes: 1000 * 60 * 60 * 2,
};

String durationString(Duration duration) {
  final mins = duration.inMinutes;
  final String str;
  if (mins > Duration.minutesPerDay * 30) {
    final months = (mins / (Duration.minutesPerDay * 30)).floor();
    final days = ((mins - (months * Duration.minutesPerDay * 30)) /
            Duration.minutesPerDay)
        .round();
    str = '${months}M ${days}d';
  } else if (mins > Duration.minutesPerDay) {
    final days = (mins / Duration.minutesPerDay).floor();
    final hours =
        ((mins - (days * Duration.minutesPerDay)) / Duration.minutesPerHour)
            .round();
    str = '${days}d ${hours}h';
  } else {
    final hours = (mins / Duration.minutesPerHour).floor();
    final _mins = (mins - (hours * Duration.minutesPerHour)).round();
    str = '${hours}h ${_mins}m';
  }
  return str;
}

Duration? parseDuration(String input) {
  final regexp = RegExp(
    r'(?<all>(?<num>0|[1-9]\d*|\.\d+|^0\.\d*|[1-9]\d*\.\d*) ?(?<dur>[smhdMy]))+',
  );
  final m = regexp
      .allMatches(input)
      .map(
        (e) => Map.fromEntries(
          e.groupNames.map((n) => MapEntry(n, e.namedGroup(n))),
        ),
      )
      .toList();
  if (m.isEmpty ||
      m.any((g) => g.values.any((v) => v == null)) ||
      input.trim().replaceAll(RegExp(r'\s+'), ' ') !=
          m.map((e) => e['all']).join(' ')) {
    return null;
  }
  return m.map((e) {
    final val = double.parse(e['num']!);
    const _m = {
      's': 1000,
      'm': 60 * 1000,
      'h': 60 * 60 * 1000,
      'd': 24 * 60 * 60 * 1000,
      'M': 30.4167 * 24 * 60 * 60 * 1000,
      'y': 365 * 24 * 60 * 60 * 1000,
    };
    return Duration(
      milliseconds: (_m[e['dur']]! * val).round(),
    );
  }).reduce((value, element) => value + element);
}

class DurationInputButton extends StatelessWidget {
  const DurationInputButton({
    Key? key,
    required this.duration,
    required this.onChanged,
    required this.title,
  }) : super(key: key);

  final Duration duration;
  final void Function(Duration) onChanged;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title),
        Builder(
          builder: (context) {
            return CustomOverlayButton.stack(
              params: defaultPortalParams,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 10.0,
                ),
                child: Text(
                  durationString(duration),
                ),
              ),
              portalBuilder: (notifier) {
                return DurationInput(
                  duration: duration,
                  onChanged: (v) {
                    notifier.hide();
                    onChanged(v);
                  },
                  onCancel: () {
                    notifier.hide();
                  },
                );
              },
            );
          },
        )
      ],
    );
  }
}

class DurationInput extends HookWidget {
  const DurationInput({
    Key? key,
    required this.duration,
    required this.onChanged,
    this.onCancel,
  }) : super(key: key);

  final Duration duration;
  final void Function(Duration p1) onChanged;
  final void Function()? onCancel;

  @override
  Widget build(BuildContext context) {
    final durationState = useState(duration);
    final onChangedText = useCallback1<Duration?>((p0) {
      if (p0 != null) durationState.value = p0;
    });
    final durationInput = useTextInput<Duration>(
      durationState.value,
      onChangedText,
      const StringInputSerializer<Duration>(
        parseDuration,
        durationString,
      ),
    );

    final rangeType = useState(DurationRangeType.hours);
    final maxMillis = maxMillisRange[rangeType.value]!;

    return SizedBox(
      width: 210,
      child: Column(
        children: [
          ButtonSelect<DurationRangeType>(
            options: DurationRangeType.values,
            selected: rangeType.value,
            asString: (v) => v.toString().split('.')[1],
            onChange: (n) {
              rangeType.value = n;
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Range:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                '''max: ${durationString(Duration(milliseconds: maxMillis))}''',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          Slider(
            value: (durationState.value.inMilliseconds.toDouble() /
                    maxMillis.toDouble())
                .clamp(0, 1),
            divisions: 60,
            onChanged: (percent) {
              durationState.value = Duration(
                milliseconds: (percent * maxMillis).round(),
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Text:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 120,
                child: TextFormField(
                  controller: durationInput.controller,
                  onChanged: durationInput.onChangedString,
                  focusNode: durationInput.focusNode,
                  decoration: InputDecoration(
                    errorText: durationInput.error,
                    errorStyle: const TextStyle(height: 0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              durationString(durationState.value),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (onCancel != null)
                OutlinedButton(
                  onPressed: () {
                    onCancel!();
                  },
                  child: const Text('Cancel'),
                ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  onChanged(durationState.value);
                },
                child: const Text('Accept'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
