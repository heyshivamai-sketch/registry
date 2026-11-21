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
        final daysInThisMonth =
            DateTime(date.year, date.month + 1, 0).day;
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
        final daysInThisMonth =
            DateTime(date.year, date.month + 1, 0).day;
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
    final effectiveCurrency = currencySymbol.isEmpty ? fallbackCurrency : currencySymbol;

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
        // 1. Month Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Text(
                monthTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              _RoundIconButton(
                icon: Icons.calendar_today_outlined,
                onPressed: _pickMonth,
              ),
              const SizedBox(width: 8),
              _RoundIconButton(
                icon: Icons.chevron_left_rounded,
                onPressed: _prevMonth,
              ),
              const SizedBox(width: 8),
              _RoundIconButton(
                icon: Icons.chevron_right_rounded,
                onPressed: _nextMonth,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // 2. Weekdays Header
        Row(
          children: const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),

        const SizedBox(height: AppSpacing.xs),

        // 3. Calendar Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 0.72,
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

            final daySubs =
                isCurrentMonthDay ? _getSubscriptionsForDay(cellDate) : <RegistrySubscription>[];
            final isToday = cellDate.year == widget.now.year &&
                cellDate.month == widget.now.month &&
                cellDate.day == widget.now.day;

            return _CalendarDayCell(
              date: cellDate,
              isCurrentMonth: isCurrentMonthDay,
              isToday: isToday,
              subscriptions: daySubs,
              onTap: isCurrentMonthDay
                  ? () => _onDayTapped(cellDate, daySubs)
                  : null,
            );
          },
        ),

        const SizedBox(height: AppSpacing.md),

        // 4. Bottom Summary Bar (Total & Upcoming)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${MoneyFormat.format(totalMoney, l10n.localeName)} ',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      TextSpan(
                        text: '\nTotal',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${MoneyFormat.format(upcomingMoney, l10n.localeName)} ',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      TextSpan(
                        text: '\nUpcoming',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 5. Selected Day Subscriptions List (if tapped)
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
    required this.subscriptions,
    this.onTap,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final List<RegistrySubscription> subscriptions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasSubs = subscriptions.isNotEmpty;

    final cellColor = hasSubs
        ? const Color(0xFF2563EB) // Vibrant blue card like in the screenshot
        : isCurrentMonth
            ? const Color(0xFFF8FAFC)
            : const Color(0xFFF1F5F9).withValues(alpha: 0.5);

    final textColor = hasSubs
        ? Colors.white
        : isCurrentMonth
            ? const Color(0xFF0F172A)
            : const Color(0xFF94A3B8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(10),
          border: isToday && !hasSubs
              ? Border.all(color: const Color(0xFF2563EB), width: 1.5)
              : null,
          boxShadow: hasSubs
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date number
            Text(
              '${date.day}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: hasSubs || isToday ? FontWeight.bold : FontWeight.w500,
                color: textColor,
              ),
            ),
            if (hasSubs) ...[
              const Spacer(),
              // Service brand badge (matches ACKO badge in screenshot)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      SubscriptionCopy.iconFor(subscriptions.first.category),
                      size: 10,
                      color: const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        subscriptions.first.serviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
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
    return Material(
      color: const Color(0xFFF1F5F9),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: const Color(0xFF334155)),
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
    final formattedDate = DateFormat.yMMMMd(l10n.localeName).format(date);

    if (subscriptions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No subscriptions due on $formattedDate',
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF64748B),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_note_rounded,
                size: 16,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(width: 6),
              Text(
                'Due on $formattedDate',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final sub in subscriptions) ...[
            InkWell(
              onTap: () => AppRoutes.openSubscriptionDetail(context, sub.id),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        SubscriptionCopy.iconFor(sub.category),
                        size: 18,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sub.serviceName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            SubscriptionCopy.cycle(l10n, sub.billingCycle),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      MoneyFormat.format(sub.amount, l10n.localeName),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
