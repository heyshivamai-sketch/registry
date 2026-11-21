import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/presentation/subscription_copy.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class SubscriptionCalendarView extends StatefulWidget {
  const SubscriptionCalendarView({
    super.key,
    required this.subscriptions,
    required this.now,
  });

  final List<RegistrySubscription> subscriptions;
  final DateTime now;

  @override
  State<SubscriptionCalendarView> createState() =>
      _SubscriptionCalendarViewState();
}

class _SubscriptionCalendarViewState extends State<SubscriptionCalendarView> {
  late DateTime _focusedMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(widget.now.year, widget.now.month, 1);
    _selectedDate = DateTime(widget.now.year, widget.now.month, widget.now.day);
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _focusedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _focusedMonth = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  bool _isSubscriptionDueOn(RegistrySubscription sub, DateTime date) {
    if (!sub.isActive) return false;
    final next = sub.nextPaymentDate;
    switch (sub.billingCycle) {
      case BillingCycle.monthly:
        final targetDay = next.day;
        final daysInThisMonth = DateTime(date.year, date.month + 1, 0).day;
        final effectiveDay =
            targetDay > daysInThisMonth ? daysInThisMonth : targetDay;
        return date.day == effectiveDay;
      case BillingCycle.weekly:
        return date.weekday == next.weekday;
      case BillingCycle.yearly:
        return date.month == next.month && date.day == next.day;
      case BillingCycle.quarterly:
        final monthDiff =
            (date.year - next.year) * 12 + (date.month - next.month);
        if (monthDiff % 3 != 0) return false;
        final daysInThisMonth = DateTime(date.year, date.month + 1, 0).day;
        final effectiveDay =
            next.day > daysInThisMonth ? daysInThisMonth : next.day;
        return date.day == effectiveDay;
    }
  }

  List<RegistrySubscription> _getSubscriptionsForDay(DateTime date) {
    return widget.subscriptions
        .where((sub) => sub.isActive && _isSubscriptionDueOn(sub, date))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInCurrentMonth = DateTime(year, month + 1, 0).day;
    final prevMonthLastDay = DateTime(year, month, 0).day;

    // Monday = 1, Sunday = 7
    final leadingDays = firstDayOfMonth.weekday - 1;
    final totalCells = ((leadingDays + daysInCurrentMonth) / 7).ceil() * 7;

    final monthName = DateFormat.MMMM(l10n.localeName).format(_focusedMonth);
    final isCurrentYear = _focusedMonth.year == widget.now.year;
    final monthTitle = isCurrentYear ? monthName : '$monthName $year';

    // Calculate monthly total and upcoming total
    var totalCents = 0;
    var upcomingCents = 0;
    String currencySymbol = '';

    for (var day = 1; day <= daysInCurrentMonth; day++) {
      final date = DateTime(year, month, day);
      final daySubs = _getSubscriptionsForDay(date);
      for (final sub in daySubs) {
        if (currencySymbol.isEmpty) {
          currencySymbol = sub.amount.currencyCode;
        }
        totalCents += sub.amount.minorUnits;
        final isUpcoming = date.isAfter(widget.now) ||
            (date.year == widget.now.year &&
                date.month == widget.now.month &&
                date.day == widget.now.day);
        if (isUpcoming) {
          upcomingCents += sub.amount.minorUnits;
        }
      }
    }

    final fallbackCurrency = widget.subscriptions
            .where((sub) => sub.isActive)
            .firstOrNull
            ?.amount
            .currencyCode ??
        'INR';
    final effectiveCurrency =
        currencySymbol.isEmpty ? fallbackCurrency : currencySymbol;

    final totalMoney = Money(
      minorUnits: totalCents,
      currencyCode: effectiveCurrency,
    );
    final upcomingMoney = Money(
      minorUnits: upcomingCents,
      currencyCode: effectiveCurrency,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Month Header & Navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Row(
            children: [
              Text(
                monthTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              _RoundIconButton(
                icon: Icons.calendar_today_outlined,
                tooltip: 'Select month',
                onPressed: _pickMonth,
              ),
              const SizedBox(width: AppSpacing.xs),
              _RoundIconButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Previous month',
                onPressed: _prevMonth,
              ),
              const SizedBox(width: AppSpacing.xs),
              _RoundIconButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Next month',
                onPressed: _nextMonth,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // 2. Executive Snapshot Cards (Total & Upcoming)
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Total',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        MoneyFormat.format(totalMoney, l10n.localeName),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDFF8F2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.upcoming_outlined,
                            size: 14,
                            color: Color(0xFF086B59),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Upcoming',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        MoneyFormat.format(upcomingMoney, l10n.localeName),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // 3. Calendar Card (Weekdays + Date Grid)
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Weekdays Header
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                      .map(
                        (day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

              // Calendar Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalCells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  childAspectRatio: 0.88,
                ),
                itemBuilder: (context, index) {
                  DateTime cellDate;
                  bool isCurrentMonthDay = true;

                  if (index < leadingDays) {
                    final prevDay = prevMonthLastDay - (leadingDays - 1 - index);
                    cellDate = DateTime(year, month - 1, prevDay);
                    isCurrentMonthDay = false;
                  } else if (index >= leadingDays + daysInCurrentMonth) {
                    final nextDay =
                        index - (leadingDays + daysInCurrentMonth) + 1;
                    cellDate = DateTime(year, month + 1, nextDay);
                    isCurrentMonthDay = false;
                  } else {
                    final day = index - leadingDays + 1;
                    cellDate = DateTime(year, month, day);
                  }

                  final daySubs = isCurrentMonthDay
                      ? _getSubscriptionsForDay(cellDate)
                      : <RegistrySubscription>[];
                  final isToday = cellDate.year == widget.now.year &&
                      cellDate.month == widget.now.month &&
                      cellDate.day == widget.now.day;
                  final isSelected = _selectedDate != null &&
                      cellDate.year == _selectedDate!.year &&
                      cellDate.month == _selectedDate!.month &&
                      cellDate.day == _selectedDate!.day;

                  return _CalendarDayCell(
                    date: cellDate,
                    isCurrentMonth: isCurrentMonthDay,
                    isToday: isToday,
                    isSelected: isSelected,
                    subscriptions: daySubs,
                    onTap: isCurrentMonthDay
                        ? () => _onDayTapped(cellDate, daySubs)
                        : null,
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // 4. Selected Day Subscriptions Drawer
        if (_selectedDate != null) ...[
          _DaySubscriptionsDrawer(
            date: _selectedDate!,
            subscriptions: _getSubscriptionsForDay(_selectedDate!),
            now: widget.now,
          ),
        ],
      ],
    );
  }

  void _onDayTapped(DateTime date, List<RegistrySubscription> subs) {
    setState(() {
      _selectedDate = date;
    });
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.subscriptions,
    this.onTap,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final List<RegistrySubscription> subscriptions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasSubs = subscriptions.isNotEmpty;

    final BoxDecoration decoration;
    final Color dateColor;

    if (!isCurrentMonth) {
      decoration = const BoxDecoration();
      dateColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.3);
    } else if (isSelected) {
      decoration = BoxDecoration(
        color: const Color(0xFF1E2B58),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E2B58).withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      );
      dateColor = Colors.white;
    } else if (hasSubs) {
      decoration = BoxDecoration(
        color: const Color(0xFFECE8FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD4CCF7),
          width: 1,
        ),
      );
      dateColor = const Color(0xFF111936);
    } else if (isToday) {
      decoration = BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary,
          width: 1.2,
        ),
      );
      dateColor = colorScheme.primary;
    } else {
      decoration = BoxDecoration(
        color: const Color(0xFFFAF9F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 0.8,
        ),
      );
      dateColor = colorScheme.onSurface;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: decoration,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Column(
          children: [
            Text(
              '${date.day}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: (hasSubs || isToday || isSelected)
                    ? FontWeight.w800
                    : FontWeight.w600,
                color: dateColor,
              ),
            ),
            if (hasSubs) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFF5544DB),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      SubscriptionCopy.iconFor(subscriptions.first.category),
                      size: 9,
                      color: isSelected
                          ? const Color(0xFF1E2B58)
                          : Colors.white,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        subscriptions.first.serviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? const Color(0xFF1E2B58)
                              : Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (subscriptions.length > 1) ...[
                const SizedBox(height: 1),
                Text(
                  '+${subscriptions.length - 1}',
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF5544DB),
                  ),
                ),
              ],
              const Spacer(),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final button = Material(
      color: colorScheme.surfaceContainerLowest,
      shape: CircleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: colorScheme.onSurface),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

class _DaySubscriptionsDrawer extends StatelessWidget {
  const _DaySubscriptionsDrawer({
    required this.date,
    required this.subscriptions,
    required this.now,
  });

  final DateTime date;
  final List<RegistrySubscription> subscriptions;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formattedDate = DateFormat.yMMMMd(l10n.localeName).format(date);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_note_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Due on $formattedDate',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (subscriptions.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${subscriptions.length} ${subscriptions.length == 1 ? "bill" : "bills"}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (subscriptions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: Color(0xFF1AA392),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No subscriptions due on $formattedDate',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            for (final sub in subscriptions) ...[
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: InkWell(
                  onTap: () => AppRoutes.openSubscriptionDetail(context, sub.id),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            SubscriptionCopy.iconFor(sub.category),
                            size: 20,
                            color: const Color(0xFF6558F5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sub.serviceName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                SubscriptionCopy.cycle(l10n, sub.billingCycle),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          MoneyFormat.format(sub.amount, l10n.localeName),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}
