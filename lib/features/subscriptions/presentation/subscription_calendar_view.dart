import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/paper_wallet_engraving.dart';
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

  void _jumpToToday() {
    setState(() {
      _focusedMonth = DateTime(widget.now.year, widget.now.month);
      _selectedDate = DateTime(
        widget.now.year,
        widget.now.month,
        widget.now.day,
      );
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
        .where((sub) => _isSubscriptionDueOn(sub, date))
        .toList();
  }

  ({
    Map<String, int> totalByCurrency,
    Map<String, int> upcomingByCurrency,
    int dueCount,
  }) _calculateMonthlyTotals() {
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final today = DateTime(widget.now.year, widget.now.month, widget.now.day);

    final totalMap = <String, int>{};
    final upcomingMap = <String, int>{};
    var dueCount = 0;

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final dueSubs = _getSubscriptionsForDay(date);
      for (final sub in dueSubs) {
        dueCount++;
        final currency = sub.amount.currencyCode;
        final amount = sub.amount.minorUnits;
        totalMap[currency] = (totalMap[currency] ?? 0) + amount;
        if (!date.isBefore(today)) {
          upcomingMap[currency] = (upcomingMap[currency] ?? 0) + amount;
        }
      }
    }

    return (
      totalByCurrency: totalMap,
      upcomingByCurrency: upcomingMap,
      dueCount: dueCount,
    );
  }

  String _formatTotalsMap(Map<String, int> totals, String locale) {
    if (totals.isEmpty) {
      final defaultCurrency = widget.subscriptions.isNotEmpty
          ? widget.subscriptions.first.amount.currencyCode
          : 'INR';
      return MoneyFormat.format(
        Money(minorUnits: 0, currencyCode: defaultCurrency),
        locale,
      );
    }
    return totals.entries
        .map(
          (e) => MoneyFormat.format(
            Money(minorUnits: e.value, currencyCode: e.key),
            locale,
          ),
        )
        .join(' + ');
  }

  bool get _isShowingCurrentMonth =>
      _focusedMonth.year == widget.now.year &&
      _focusedMonth.month == widget.now.month;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();

    final totals = _calculateMonthlyTotals();
    final totalText = _formatTotalsMap(totals.totalByCurrency, locale);
    final upcomingText = _formatTotalsMap(totals.upcomingByCurrency, locale);

    final selectedDate =
        _selectedDate ??
        DateTime(widget.now.year, widget.now.month, widget.now.day);
    final selectedSubs = _getSubscriptionsForDay(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CalendarHeroHeader(
          focusedMonth: _focusedMonth,
          locale: locale,
          totalText: totalText,
          upcomingText: upcomingText,
          dueCount: totals.dueCount,
          showTodayButton: !_isShowingCurrentMonth,
          onPrev: _prevMonth,
          onNext: _nextMonth,
          onPickMonth: _pickMonth,
          onJumpToday: _jumpToToday,
        ),
        const SizedBox(height: AppSpacing.md),
        _CalendarGridCard(
          focusedMonth: _focusedMonth,
          today: DateTime(widget.now.year, widget.now.month, widget.now.day),
          selectedDate: selectedDate,
          getSubscriptionsForDay: _getSubscriptionsForDay,
          onSelectDate: (date) => setState(() => _selectedDate = date),
        ),
        const SizedBox(height: AppSpacing.md),
        _SelectedDayAgendaCard(
          selectedDate: selectedDate,
          subscriptions: selectedSubs,
          locale: locale,
        ),
      ],
    );
  }
}

class _CalendarHeroHeader extends StatelessWidget {
  const _CalendarHeroHeader({
    required this.focusedMonth,
    required this.locale,
    required this.totalText,
    required this.upcomingText,
    required this.dueCount,
    required this.showTodayButton,
    required this.onPrev,
    required this.onNext,
    required this.onPickMonth,
    required this.onJumpToday,
  });

  final DateTime focusedMonth;
  final String locale;
  final String totalText;
  final String upcomingText;
  final int dueCount;
  final bool showTodayButton;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPickMonth;
  final VoidCallback onJumpToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthName = DateFormat.MMMM(locale).format(focusedMonth);
    final yearText = DateFormat.y(locale).format(focusedMonth);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.passRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.heroStart, AppColors.heroEnd],
        ),
        boxShadow: AppShadows.pulse(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.passRadius),
        child: Stack(
          children: [
            const Positioned.fill(
              child: PaperWalletEngraving(opacity: 0.08),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: onPickMonth,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    monthName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          fontFamily: AppTypography.serifFamily,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: -0.3,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    yearText,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: Colors.white.withValues(alpha: 0.72),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (showTodayButton) ...[
                        Material(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          child: InkWell(
                            onTap: onJumpToday,
                            borderRadius: BorderRadius.circular(999),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Text(
                                'Today',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      _HeroNavButton(
                        icon: Icons.chevron_left_rounded,
                        tooltip: 'Previous month',
                        onTap: onPrev,
                      ),
                      const SizedBox(width: 6),
                      _HeroNavButton(
                        icon: Icons.chevron_right_rounded,
                        tooltip: 'Next month',
                        onTap: onNext,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _HeroStatColumn(
                            label: 'Total',
                            value: totalText,
                            caption: dueCount == 0
                                ? 'No bills this month'
                                : dueCount == 1
                                    ? '1 renewal'
                                    : '$dueCount renewals',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                        Expanded(
                          child: _HeroStatColumn(
                            label: 'Upcoming',
                            value: upcomingText,
                            caption: 'Remaining this month',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroNavButton extends StatelessWidget {
  const _HeroNavButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _HeroStatColumn extends StatelessWidget {
  const _HeroStatColumn({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            maxLines: 1,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _CalendarGridCard extends StatelessWidget {
  const _CalendarGridCard({
    required this.focusedMonth,
    required this.today,
    required this.selectedDate,
    required this.getSubscriptionsForDay,
    required this.onSelectDate,
  });

  final DateTime focusedMonth;
  final DateTime today;
  final DateTime selectedDate;
  final List<RegistrySubscription> Function(DateTime) getSubscriptionsForDay;
  final ValueChanged<DateTime> onSelectDate;

  static const _weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final firstOfMonth = DateTime(focusedMonth.year, focusedMonth.month);
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday - 1;
    final totalCells = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;

    final rows = <Widget>[];
    for (var start = 0; start < totalCells; start += 7) {
      final rowChildren = <Widget>[];
      for (var col = 0; col < 7; col++) {
        final index = start + col;
        final dayOffset = index - leadingBlanks + 1;
        if (dayOffset < 1 || dayOffset > daysInMonth) {
          final overflowDate = DateTime(
            focusedMonth.year,
            focusedMonth.month,
            dayOffset,
          );
          rowChildren.add(
            Expanded(
              child: SizedBox(
                height: 54,
                child: Center(
                  child: Text(
                    '${overflowDate.day}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.35),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          final date = DateTime(
            focusedMonth.year,
            focusedMonth.month,
            dayOffset,
          );
          final isToday = date == today;
          final isSelected = date == selectedDate;
          final dueSubs = getSubscriptionsForDay(date);

          rowChildren.add(
            Expanded(
              child: _CalendarDayCell(
                date: date,
                isToday: isToday,
                isSelected: isSelected,
                dueSubs: dueSubs,
                onTap: () => onSelectDate(date),
              ),
            ),
          );
        }
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: rowChildren),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: AppShadows.card(context),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final day in _weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 4),
          ...rows,
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.dueSubs,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final List<RegistrySubscription> dueSubs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSubs = dueSubs.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        height: 54,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.deepNavy
              : hasSubs
                  ? AppColors.indigoContainer.withValues(alpha: 0.75)
                  : isToday
                      ? AppColors.surfaceContainer
                      : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isToday && !isSelected
              ? Border.all(
                  color: AppColors.deepNavy.withValues(alpha: 0.45),
                  width: 1.2,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? Colors.white
                    : isToday
                        ? AppColors.deepNavy
                        : AppColors.midnight,
                fontWeight: (isSelected || isToday || hasSubs)
                    ? FontWeight.w700
                    : FontWeight.w500,
                fontSize: 13.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 3),
            if (hasSubs)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.deepNavy.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dueSubs.length == 1
                      ? dueSubs.first.serviceName
                      : '${dueSubs.first.serviceName} +${dueSubs.length - 1}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.deepNavy,
                  ),
                ),
              )
            else if (isToday)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.white : AppColors.deepNavy,
                ),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _SelectedDayAgendaCard extends StatelessWidget {
  const _SelectedDayAgendaCard({
    required this.selectedDate,
    required this.subscriptions,
    required this.locale,
  });

  final DateTime selectedDate;
  final List<RegistrySubscription> subscriptions;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final formattedDate = DateFormat.yMMMMd(locale).format(selectedDate);

    if (subscriptions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: AppShadows.card(context),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.successContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 20,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No subscriptions due on $formattedDate',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'All clear for this day.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: AppShadows.card(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Due on $formattedDate',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.indigoContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  subscriptions.length == 1
                      ? '1 bill'
                      : '${subscriptions.length} bills',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.deepNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < subscriptions.length; i++) ...[
            if (i > 0)
              Divider(
                height: 16,
                thickness: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            _AgendaSubscriptionRow(
              subscription: subscriptions[i],
              cycleLabel: SubscriptionCopy.cycle(
                l10n,
                subscriptions[i].billingCycle,
              ),
              amountLabel: MoneyFormat.format(
                subscriptions[i].amount,
                locale,
              ),
              onTap: () => AppRoutes.openSubscriptionDetail(
                context,
                subscriptions[i].id,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AgendaSubscriptionRow extends StatelessWidget {
  const _AgendaSubscriptionRow({
    required this.subscription,
    required this.cycleLabel,
    required this.amountLabel,
    required this.onTap,
  });

  final RegistrySubscription subscription;
  final String cycleLabel;
  final String amountLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = subscription.serviceName.trim().isEmpty
        ? 'S'
        : subscription.serviceName.trim().substring(0, 1).toUpperCase();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.indigoContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                initial,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.deepNavy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subscription.serviceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cycleLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amountLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
