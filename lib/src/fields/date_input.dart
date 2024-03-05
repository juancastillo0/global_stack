import 'package:flutter/material.dart';

import '../../fields.dart';

class DateInput extends StatelessWidget {
  const DateInput({
    Key? key,
    required this.title,
    required this.date,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.params,
  }) : super(key: key);

  final String title;
  final DateTime? date;
  final OnChange<DateTime> onChanged;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateParams? params;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            if (!onChanged.isRequired && date != null)
              InkWell(
                onTap: () {
                  onChanged(null);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 2,
                  ),
                  child: Text(
                    'RESET',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              )
          ],
        ),
        Builder(
          builder: (context) {
            final String dateStr;
            final _date = date;
            if (_date == null) {
              dateStr = 'Not configured';
            } else {
              final now = DateTime.now();
              final sameYear = now.year != _date.year;
              final sameMonth = now.month != _date.month;
              final sameDay = now.day != _date.day;
              dateStr = '${sameYear ? '' : '${_date.year}-'}'
                  '${sameYear && sameMonth ? '' : '${_date.month}-'}'
                  '${sameYear && sameMonth && sameDay ? '' : '${_date.day}'}';
            }
            return InkWell(
              onTap: () async {
                final result = await showDatePicker(
                  context: context,
                  initialDate:
                      date ?? DateTime.now().add(const Duration(days: 1)),
                  firstDate: firstDate,
                  lastDate: lastDate,
                  currentDate: params?.currentDate,
                  initialEntryMode:
                      params?.initialEntryMode ?? DatePickerEntryMode.calendar,
                  selectableDayPredicate: params?.selectableDayPredicate,
                  helpText: params?.helpText,
                  cancelText: params?.cancelText,
                  confirmText: params?.confirmText,
                  locale: params?.locale,
                  useRootNavigator: params?.useRootNavigator ?? true,
                  routeSettings: params?.routeSettings,
                  textDirection: params?.textDirection,
                  builder: params?.builder,
                  initialDatePickerMode:
                      params?.initialDatePickerMode ?? DatePickerMode.day,
                  errorFormatText: params?.errorFormatText,
                  errorInvalidText: params?.errorInvalidText,
                  fieldHintText: params?.fieldHintText,
                  fieldLabelText: params?.fieldLabelText,
                );
                if (result != null) {
                  onChanged(result);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 10.0,
                ),
                child: Text(
                  dateStr,
                ),
              ),
            );
          },
        )
      ],
    );
  }
}

class DateParams {
  final DateTime? currentDate;
  final DatePickerEntryMode initialEntryMode;
  final SelectableDayPredicate? selectableDayPredicate;
  final String? helpText;
  final String? cancelText;
  final String? confirmText;
  final Locale? locale;
  final bool useRootNavigator;
  final RouteSettings? routeSettings;
  final TextDirection? textDirection;
  final TransitionBuilder? builder;
  final DatePickerMode initialDatePickerMode;
  final String? errorFormatText;
  final String? errorInvalidText;
  final String? fieldHintText;
  final String? fieldLabelText;

  const DateParams({
    this.currentDate,
    this.selectableDayPredicate,
    this.helpText,
    this.cancelText,
    this.confirmText,
    this.locale,
    this.routeSettings,
    this.textDirection,
    this.builder,
    this.errorFormatText,
    this.errorInvalidText,
    this.fieldHintText,
    this.fieldLabelText,
    this.useRootNavigator = true,
    this.initialDatePickerMode = DatePickerMode.day,
    this.initialEntryMode = DatePickerEntryMode.calendar,
  });
}
