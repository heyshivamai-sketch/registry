import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/money.dart';
import '../domain/registry_subscription.dart';
import 'subscription_copy.dart';

class SubscriptionCalendarView extends StatefulWidget {
  const SubscriptionCalendarView({
    required this.subscriptions,
    required this.now,
    super.key,
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
    _focusedMonth = DateTime(widget.now.year, widget.now.month);
    _selectedDate = DateTime(widget.now.year, widget.now.month, widget.now.day);
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
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
        _focusedMonth = DateTime(picked.year, picked.month);
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
    final firstDayOfMonth = DateTime(year, month);
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
    var activeBillsCount = 0;
    String currencySymbol = '';

    for (var day = 1; day <= daysInCurrentMonth; day++) {
      final date = DateTime(year, month, day);
      final daySubs = _getSubscriptionsForDay(date);
      activeBillsCount += daySubs.length;
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

    final isViewingCurrentMonth = _focusedMonth.year == widget.now.year &&
        _focusedMonth.month == widget.now.month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Month Header & Navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        monthTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppColors.midnight,
                          fontSize: 22,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (activeBillsCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECE8FB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.violet.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          '$activeBillsCount ${activeBillsCount == 1 ? "bill" : "bills"}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.violet,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isViewingCurrentMonth) ...[
                TextButton(
                  onPressed: () {
                    setState(() {
                      _focusedMonth =
                          DateTime(widget.now.year, widget.now.month);
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Today',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.violet,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              _RoundIconButton(
                icon: Icons.calendar_today_outlined,
                onPressed: _pickMonth,
              ),
              const SizedBox(width: 6),
              _RoundIconButton(
                icon: Icons.chevron_left_rounded,
                onPressed: _prevMonth,
              ),
              const SizedBox(width: 6),
              _RoundIconButton(
                icon: Icons.chevron_right_rounded,
                onPressed: _nextMonth,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // 2. Weekdays Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              for (final day in ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'])
                Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: (day == 'Sa' || day == 'Su')
                            ? AppColors.violet
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 3. Calendar Grid (individual card tiles matching Registry Aura theme)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: totalCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            childAspectRatio: 0.86,
          ),
          itemBuilder: (context, index) {
            DateTime cellDate;
            bool isCurrentMonthDay = true;

            if (index < leadingDays) {
              final prevDay = prevMonthLastDay - (leadingDays - 1 - index);
              cellDate = DateTime(year, month - 1, prevDay);
              isCurrentMonthDay = false;
            } else if (index >= leadingDays + daysInCurrentMonth) {
              final nextDay = index - (leadingDays + daysInCurrentMonth) + 1;
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
              subscriptions: daySubs,
              isSelected: isSelected,
              onTap: isCurrentMonthDay
                  ? () => _onDayTapped(cellDate, daySubs)
                  : null,
            );
          },
        ),

        const SizedBox(height: AppSpacing.sm),

        // 4. Executive Summary Card (Total & Upcoming)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECE8FB),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 14,
                                color: AppColors.violet,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Total',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
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
                              letterSpacing: -0.4,
                              color: AppColors.midnight,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 38,
                    color: colorScheme.outlineVariant,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  Expanded(
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
                                Icons.upcoming_rounded,
                                size: 14,
                                color: Color(0xFF086B59),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Upcoming',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
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
                              letterSpacing: -0.4,
                              color: AppColors.midnight,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (totalCents > 0) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 5,
                    child: Row(
                      children: [
                        if (totalCents - upcomingCents > 0)
                          Expanded(
                            flex: totalCents - upcomingCents,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF086B59),
                              ),
                            ),
                          ),
                        if (upcomingCents > 0)
                          Expanded(
                            flex: upcomingCents,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: AppColors.violet,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // 5. Selected Day Subscriptions Drawer
        if (_selectedDate != null) ...[
          const SizedBox(height: AppSpacing.sm),
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
    required this.subscriptions,
    this.isSelected = false,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasSubs = subscriptions.isNotEmpty;

    final Color? cellColor;
    final Gradient? gradient;
    final Color textColor;
    Border? border;
    List<BoxShadow>? shadows;

    if (hasSubs) {
      // Signature Registry Aura dark midnight/navy gradient
      cellColor = null;
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF141D43), Color(0xFF283E79)],
      );
      textColor = Colors.white;
      if (isSelected) {
        border = Border.all(color: Colors.white, width: 2);
        shadows = [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.45),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ];
      } else {
        shadows = [
          BoxShadow(
            color: const Color(0xFF141D43).withValues(alpha: 0.22),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ];
      }
    } else if (isCurrentMonth) {
      cellColor = isSelected ? const Color(0xFFF3F0FC) : colorScheme.surface;
      gradient = null;
      textColor = AppColors.midnight;
      if (isSelected) {
        border = Border.all(color: AppColors.violet, width: 1.8);
        shadows = [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.2),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ];
      } else if (isToday) {
        border = Border.all(
          color: AppColors.violet.withValues(alpha: 0.75),
          width: 1.4,
        );
      } else {
        border = Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          width: 0.9,
        );
      }
    } else {
      cellColor = Colors.transparent;
      gradient = null;
      textColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.35);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: cellColor,
          gradient: gradient,
          borderRadius: BorderRadius.circular(11),
          border: border,
          boxShadow: shadows,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 3.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date number
            Text(
              '${date.day}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: hasSubs || isToday || isSelected
                    ? FontWeight.w800
                    : FontWeight.w600,
                color: isToday && !hasSubs ? AppColors.violet : textColor,
              ),
            ),
            if (isToday && !hasSubs) ...[
              const SizedBox(height: 1.5),
              Center(
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.violet,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
            if (hasSubs) ...[
              const Spacer(),
              // Service brand badge (compact, high-contrast, fully theme matched)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 3,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    subscriptions.first.serviceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF141D43),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              if (subscriptions.length > 1) ...[
                const SizedBox(height: 1),
                Text(
                  '+${subscriptions.length - 1} more',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      shape: CircleBorder(
        side: BorderSide(color: colorScheme.outlineVariant, width: 1.1),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 0.5,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.05),
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: AppColors.midnight),
        ),
      ),
    );
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

    if (subscriptions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F8FD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant, width: 1.1),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFDFF8F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: Color(0xFF086B59),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No subscriptions due on $formattedDate',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.midnight,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'No renewals scheduled for this day',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    var dayTotalMinor = 0;
    final dayCurrency = subscriptions.first.amount.currencyCode;
    for (final sub in subscriptions) {
      dayTotalMinor += sub.amount.minorUnits;
    }
    final dayTotalMoney = Money(
      minorUnits: dayTotalMinor,
      currencyCode: dayCurrency,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant, width: 1.1),
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
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECE8FB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  size: 16,
                  color: AppColors.violet,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Due on $formattedDate',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.midnight,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECE8FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  MoneyFormat.format(dayTotalMoney, l10n.localeName),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.violet,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final sub in subscriptions) ...[
            Material(
              color: colorScheme.surfaceContainerLowest,
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
                          color: const Color(0xFFECE8FB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          SubscriptionCopy.iconFor(sub.category),
                          size: 19,
                          color: AppColors.violet,
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
                                color: AppColors.midnight,
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
                          color: AppColors.midnight,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
