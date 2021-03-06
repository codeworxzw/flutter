// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbols.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

import 'colors.dart';
import 'debug.dart';
import 'icon.dart';
import 'icon_button.dart';
import 'icons.dart';
import 'ink_well.dart';
import 'theme.dart';
import 'typography.dart';

enum _DatePickerMode { day, year }

/// A material design date picker.
///
/// The date picker widget is rarely used directly. Instead, consider using
/// [showDatePicker], which creates a date picker dialog.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [showDatePicker]
///  * <https://www.google.com/design/spec/components/pickers.html#pickers-date-pickers>
class DatePicker extends StatefulWidget {
  /// Creates a date picker.
  ///
  /// Rather than creating a date picker directly, consider using
  /// [showDatePicker] to show a date picker in a dialog.
  DatePicker({
    Key key,
    @required this.selectedDate,
    @required this.onChanged,
    @required this.firstDate,
    @required this.lastDate
  }) : super(key: key) {
    assert(selectedDate != null);
    assert(firstDate != null);
    assert(lastDate != null);
  }

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedDate;

  /// Called when the user picks a date.
  final ValueChanged<DateTime> onChanged;

  /// The earliest date the user is permitted to pick.
  final DateTime firstDate;

  /// The latest date the user is permitted to pick.
  final DateTime lastDate;

  @override
  _DatePickerState createState() => new _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  _DatePickerMode _mode = _DatePickerMode.day;

  void _handleModeChanged(_DatePickerMode mode) {
    HapticFeedback.vibrate();
    setState(() {
      _mode = mode;
    });
  }

  void _handleYearChanged(DateTime dateTime) {
    HapticFeedback.vibrate();
    setState(() {
      _mode = _DatePickerMode.day;
    });
    if (config.onChanged != null)
      config.onChanged(dateTime);
  }

  void _handleDayChanged(DateTime dateTime) {
    HapticFeedback.vibrate();
    if (config.onChanged != null)
      config.onChanged(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    Widget header = new _DatePickerHeader(
      selectedDate: config.selectedDate,
      mode: _mode,
      onModeChanged: _handleModeChanged
    );
    Widget picker;
    switch (_mode) {
      case _DatePickerMode.day:
        picker = new MonthPicker(
          selectedDate: config.selectedDate,
          onChanged: _handleDayChanged,
          firstDate: config.firstDate,
          lastDate: config.lastDate
        );
        break;
      case _DatePickerMode.year:
        picker = new YearPicker(
          selectedDate: config.selectedDate,
          onChanged: _handleYearChanged,
          firstDate: config.firstDate,
          lastDate: config.lastDate
        );
        break;
    }
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        header,
        new Container(
          height: _kMaxDayPickerHeight,
          child: picker
        )
      ]
    );
  }

}

// Shows the selected date in large font and toggles between year and day mode
class _DatePickerHeader extends StatelessWidget {
  _DatePickerHeader({
    Key key,
    @required this.selectedDate,
    @required this.mode,
    @required this.onModeChanged
  }) : super(key: key) {
    assert(selectedDate != null);
    assert(mode != null);
  }

  final DateTime selectedDate;
  final _DatePickerMode mode;
  final ValueChanged<_DatePickerMode> onModeChanged;

  void _handleChangeMode(_DatePickerMode value) {
    if (value != mode)
      onModeChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    TextTheme headerTextTheme = themeData.primaryTextTheme;
    Color dayColor;
    Color yearColor;
    switch(themeData.primaryColorBrightness) {
      case Brightness.light:
        dayColor = mode == _DatePickerMode.day ? Colors.black87 : Colors.black54;
        yearColor = mode == _DatePickerMode.year ? Colors.black87 : Colors.black54;
        break;
      case Brightness.dark:
        dayColor = mode == _DatePickerMode.day ? Colors.white : Colors.white70;
        yearColor = mode == _DatePickerMode.year ? Colors.white : Colors.white70;
        break;
    }
    TextStyle dayStyle = headerTextTheme.display1.copyWith(color: dayColor, height: 1.4);
    TextStyle yearStyle = headerTextTheme.subhead.copyWith(color: yearColor, height: 1.4);

    Color backgroundColor;
    switch (themeData.brightness) {
      case Brightness.light:
        backgroundColor = themeData.primaryColor;
        break;
      case Brightness.dark:
        backgroundColor = themeData.backgroundColor;
        break;
    }

    return new Container(
      height: 100.0,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      decoration: new BoxDecoration(backgroundColor: backgroundColor),
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new GestureDetector(
            onTap: () => _handleChangeMode(_DatePickerMode.year),
            child: new Text(new DateFormat('yyyy').format(selectedDate), style: yearStyle)
          ),
          new GestureDetector(
            onTap: () => _handleChangeMode(_DatePickerMode.day),
            child: new Text(new DateFormat('MMMEd').format(selectedDate), style: dayStyle)
          ),
        ]
      )
    );
  }
}

const Duration _kMonthScrollDuration = const Duration(milliseconds: 200);
const double _kDayPickerRowHeight = 42.0;
const int _kMaxDayPickerRowCount = 6; // A 31 day month that starts on Saturday.
// Two extra rows: one for the day-of-week header and one for the month header.
const double _kMaxDayPickerHeight = _kDayPickerRowHeight * (_kMaxDayPickerRowCount + 2);

class _DayPickerGridDelegate extends GridDelegateWithInOrderChildPlacement {
  @override
  GridSpecification getGridSpecification(BoxConstraints constraints, int childCount) {
    assert(constraints.maxWidth < double.INFINITY);
    final int columnCount = DateTime.DAYS_PER_WEEK;
    return new GridSpecification.fromRegularTiles(
      tileWidth: constraints.maxWidth / columnCount,
      tileHeight: _kDayPickerRowHeight,
      columnCount: columnCount,
      rowCount: (childCount / columnCount).ceil()
    );
  }
}

final _DayPickerGridDelegate _kDayPickerGridDelegate = new _DayPickerGridDelegate();

/// Displays the days of a given month and allows choosing a day.
///
/// The days are arranged in a rectangular grid with one column for each day of
/// the week.
///
/// Part of the material design [DatePicker].
///
/// See also:
///
///  * [DatePicker].
///  * <https://www.google.com/design/spec/components/pickers.html#pickers-date-pickers>
class DayPicker extends StatelessWidget {
  /// Creates a day picker.
  ///
  /// Rarely used directly. Instead, typically used as part of a [DatePicker].
  DayPicker({
    Key key,
    @required this.selectedDate,
    @required this.currentDate,
    @required this.onChanged,
    @required this.displayedMonth
  }) : super(key: key) {
    assert(selectedDate != null);
    assert(currentDate != null);
    assert(onChanged != null);
    assert(displayedMonth != null);
  }

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedDate;

  /// The current date at the time the picker is displayed.
  final DateTime currentDate;

  /// Called when the user picks a day.
  final ValueChanged<DateTime> onChanged;

  /// The month whose days are displayed by this picker.
  final DateTime displayedMonth;

  List<Widget> _getDayHeaders(TextStyle headerStyle) {
    final DateFormat dateFormat = new DateFormat();
    final DateSymbols symbols = dateFormat.dateSymbols;
    return symbols.NARROWWEEKDAYS.map((String weekDay) {
      return new Center(child: new Text(weekDay, style: headerStyle));
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final int year = displayedMonth.year;
    final int month = displayedMonth.month;
    // Dart's Date time constructor is very forgiving and will understand
    // month 13 as January of the next year. :)
    final int daysInMonth = new DateTime(year, month + 1).difference(new DateTime(year, month)).inDays;
    // This assumes a start day of SUNDAY, but could be changed.
    final int firstWeekday = new DateTime(year, month).weekday % 7;
    final List<Widget> labels = <Widget>[];
    labels.addAll(_getDayHeaders(themeData.textTheme.caption));
    for (int i = 0; true; ++i) {
      final int day = i - firstWeekday + 1;
      if (day > daysInMonth)
        break;
      if (day < 1) {
        labels.add(new Container());
      } else {
        BoxDecoration decoration;
        TextStyle itemStyle = themeData.textTheme.body1;

        if (selectedDate.year == year && selectedDate.month == month && selectedDate.day == day) {
          // The selected day gets a circle background highlight, and a contrasting text color.
          itemStyle = themeData.textTheme.body2.copyWith(
            color: (themeData.brightness == Brightness.light) ? Colors.white : Colors.black87
          );
          decoration = new BoxDecoration(
            backgroundColor: themeData.accentColor,
            shape: BoxShape.circle
          );
        } else if (currentDate.year == year && currentDate.month == month && currentDate.day == day) {
          // The current day gets a different text color.
          itemStyle = themeData.textTheme.body2.copyWith(color: themeData.accentColor);
        }

        labels.add(new GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            DateTime result = new DateTime(year, month, day);
            onChanged(result);
          },
          child: new Container(
            decoration: decoration,
            child: new Center(
              child: new Text(day.toString(), style: itemStyle)
            )
          )
        ));
      }
    }

    return new Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: new Column(
        children: <Widget>[
          new Container(
            height: _kDayPickerRowHeight,
            child: new Center(
              child: new Text(new DateFormat('yMMMM').format(displayedMonth),
                style: themeData.textTheme.subhead
              )
            )
          ),
          new CustomGrid(
            delegate: _kDayPickerGridDelegate,
            children: labels
          )
        ]
      )
    );
  }
}

/// A scrollable list of months to allow picking a month.
///
/// Shows the days of each month in a rectangular grid with one column for each
/// day of the week.
///
/// Part of the material design [DatePicker].
///
/// See also:
///
///  * [DatePicker]
///  * <https://www.google.com/design/spec/components/pickers.html#pickers-date-pickers>
class MonthPicker extends StatefulWidget {
  /// Creates a month picker.
  ///
  /// Rarely used directly. Instead, typically used as part of a [DatePicker].
  MonthPicker({
    Key key,
    @required this.selectedDate,
    @required this.onChanged,
    @required this.firstDate,
    @required this.lastDate
  }) : super(key: key) {
    assert(selectedDate != null);
    assert(onChanged != null);
    assert(lastDate.isAfter(firstDate));
    assert(selectedDate.isAfter(firstDate) || selectedDate.isAtSameMomentAs(firstDate));
  }

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedDate;

  /// Called when the user picks a month.
  final ValueChanged<DateTime> onChanged;

  /// The earliest date the user is permitted to pick.
  final DateTime firstDate;

  /// The latest date the user is permitted to pick.
  final DateTime lastDate;

  @override
  _MonthPickerState createState() => new _MonthPickerState();
}

class _MonthPickerState extends State<MonthPicker> {
  @override
  void initState() {
    super.initState();
    _updateCurrentDate();
  }

  @override
  void didUpdateConfig(MonthPicker oldConfig) {
    if (config.selectedDate != oldConfig.selectedDate)
      _dayPickerListKey = new GlobalKey<ScrollableState>();
  }

  DateTime _currentDate;
  Timer _timer;
  GlobalKey<ScrollableState> _dayPickerListKey = new GlobalKey<ScrollableState>();

  void _updateCurrentDate() {
    _currentDate = new DateTime.now();
    DateTime tomorrow = new DateTime(_currentDate.year, _currentDate.month, _currentDate.day + 1);
    Duration timeUntilTomorrow = tomorrow.difference(_currentDate);
    timeUntilTomorrow += const Duration(seconds: 1);  // so we don't miss it by rounding
    if (_timer != null)
      _timer.cancel();
    _timer = new Timer(timeUntilTomorrow, () {
      setState(() {
        _updateCurrentDate();
      });
    });
  }

  int _monthDelta(DateTime startDate, DateTime endDate) {
    return (endDate.year - startDate.year) * 12 + endDate.month - startDate.month;
  }

  List<Widget> _buildItems(BuildContext context, int start, int count) {
    final List<Widget> result = new List<Widget>();
    final DateTime startDate = new DateTime(config.firstDate.year + start ~/ 12, config.firstDate.month + start % 12);
    for (int i = 0; i < count; ++i) {
      DateTime displayedMonth = new DateTime(startDate.year + i ~/ 12, startDate.month + i % 12);
      result.add(new DayPicker(
        key: new ValueKey<DateTime>(displayedMonth),
        selectedDate: config.selectedDate,
        currentDate: _currentDate,
        onChanged: config.onChanged,
        displayedMonth: displayedMonth
      ));
    }
    return result;
  }

  void _handleNextMonth() {
    ScrollableState state = _dayPickerListKey.currentState;
    state?.scrollTo(state.scrollOffset.round() + 1.0, duration: _kMonthScrollDuration);
  }

  void _handlePreviousMonth() {
    ScrollableState state = _dayPickerListKey.currentState;
    state?.scrollTo(state.scrollOffset.round() - 1.0, duration: _kMonthScrollDuration);
  }

  @override
  Widget build(BuildContext context) {
    return new Stack(
      children: <Widget>[
        new PageableLazyList(
          key: _dayPickerListKey,
          initialScrollOffset: _monthDelta(config.firstDate, config.selectedDate).toDouble(),
          scrollDirection: Axis.horizontal,
          itemCount: _monthDelta(config.firstDate, config.lastDate) + 1,
          itemBuilder: _buildItems
        ),
        new Positioned(
          top: 0.0,
          left: 8.0,
          child: new IconButton(
            icon: new Icon(Icons.chevron_left),
            tooltip: 'Previous month',
            onPressed: _handlePreviousMonth
          )
        ),
        new Positioned(
          top: 0.0,
          right: 8.0,
          child: new IconButton(
            icon: new Icon(Icons.chevron_right),
            tooltip: 'Next month',
            onPressed: _handleNextMonth
          )
        )
      ]
    );
  }

  @override
  void dispose() {
    if (_timer != null)
      _timer.cancel();
    super.dispose();
  }
}

/// A scrollable list of years to allow picking a year.
///
/// Part of the material design [DatePicker].
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [DatePicker]
///  * <https://www.google.com/design/spec/components/pickers.html#pickers-date-pickers>
class YearPicker extends StatefulWidget {
  /// Creates a year picker.
  ///
  /// The [selectedDate] and [onChanged] arguments must not be null. The
  /// [lastDate] must be after the [firstDate].
  ///
  /// Rarely used directly. Instead, typically used as part of a [DatePicker].
  YearPicker({
    Key key,
    @required this.selectedDate,
    @required this.onChanged,
    @required this.firstDate,
    @required this.lastDate
  }) : super(key: key) {
    assert(selectedDate != null);
    assert(onChanged != null);
    assert(lastDate.isAfter(firstDate));
  }

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedDate;

  /// Called when the user picks a year.
  final ValueChanged<DateTime> onChanged;

  /// The earliest date the user is permitted to pick.
  final DateTime firstDate;

  /// The latest date the user is permitted to pick.
  final DateTime lastDate;

  @override
  _YearPickerState createState() => new _YearPickerState();
}

class _YearPickerState extends State<YearPicker> {
  static const double _itemExtent = 50.0;

  List<Widget> _buildItems(BuildContext context, int start, int count) {
    final ThemeData themeData = Theme.of(context);
    final TextStyle style = themeData.textTheme.body1;
    final List<Widget> items = new List<Widget>();
    for (int i = start; i < start + count; i++) {
      final int year = config.firstDate.year + i;
      final TextStyle itemStyle = year == config.selectedDate.year ?
        themeData.textTheme.headline.copyWith(color: themeData.accentColor) : style;
      items.add(new InkWell(
        key: new ValueKey<int>(year),
        onTap: () {
          config.onChanged(new DateTime(year, config.selectedDate.month, config.selectedDate.day));
        },
        child: new Center(
          child: new Text(year.toString(), style: itemStyle)
        )
      ));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    return new ScrollableLazyList(
      itemExtent: _itemExtent,
      itemCount: config.lastDate.year - config.firstDate.year + 1,
      itemBuilder: _buildItems
    );
  }
}
