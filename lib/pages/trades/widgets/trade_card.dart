import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../models/trade.dart';

class TradeCard extends StatefulWidget {
  final TradeItem trade;

  const TradeCard({super.key, required this.trade});

  @override
  State<TradeCard> createState() => _TradeCardState();
}

class _TradeCardState extends State<TradeCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  static final _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 0,
  );

  static final _inrFormatDecimal = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    final trade = widget.trade;
    final pnl = trade.pnl;
    final pnlColor = AppTheme.pnlColor(pnl);
    final pnlSign = pnl >= 0 ? '+' : '';
    final isClosed = trade.status == 'closed';
    final isIronCondor = trade.tradeType == 'iron_condor';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        children: [
          // Tappable header
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Trade type + date range
                  Row(
                    children: [
                      _entryModeBadge(trade.entryMode),
                      const SizedBox(width: 8),
                      Text(
                        trade.tradeTypeDisplay,
                        style: const TextStyle(
                          color: Color(0xFFC9D1D9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _dateRange(trade),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey.shade500,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 2: Strike info
                  Text(
                    _strikesDisplay(trade, isIronCondor),
                    style: const TextStyle(
                      color: Color(0xFF8B949E),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Row 3: Lots, Margin, Total Credit, PnL
                  Row(
                    children: [
                      _chip('${trade.numLots} lot${trade.numLots > 1 ? 's' : ''}'),
                      const SizedBox(width: 6),
                      if (trade.capitalDeployed != null) ...[
                        _chip(_compactInr(trade.capitalDeployed!)),
                        const SizedBox(width: 6),
                      ],
                      if (trade.totalCredit != null) ...[
                        _chip(
                          'Cr ${_inrFormat.format(trade.totalCredit)}',
                        ),
                        const SizedBox(width: 6),
                      ],
                      const Spacer(),
                      // PnL display
                      Text(
                        '$pnlSign${_inrFormatDecimal.format(pnl)}',
                        style: TextStyle(
                          color: pnlColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (trade.currentPnlPct != null ||
                          (isClosed && trade.realizedPnl != null)) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: pnlColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            _pnlPctText(trade),
                            style: TextStyle(
                              color: pnlColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // PnL progress bar (only for open trades)
                  if (!isClosed && trade.creditReceived != null) ...[
                    const SizedBox(height: 8),
                    _pnlProgressBar(trade),
                  ],
                ],
              ),
            ),
          ),

          // Expanded details
          if (_expanded) _buildExpandedDetails(trade, isClosed),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(TradeItem trade, bool isClosed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF30363D)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Entry details
            _detailRow('Entry Spot', trade.entrySpot.toStringAsFixed(2)),
            if (trade.entryTime != null)
              _detailRow('Entry Time', trade.entryTime!),
            if (trade.expiry != null) _detailRow('Expiry', trade.expiry!),
            if (trade.totalCredit != null)
              _detailRow(
                'Total Credit',
                _inrFormatDecimal.format(trade.totalCredit),
              ),
            if (trade.capitalDeployed != null)
              _detailRow(
                'Capital Deployed',
                _inrFormat.format(trade.capitalDeployed),
              ),
            if (trade.positionSizePct != null)
              _detailRow(
                'Position Size',
                '${(trade.positionSizePct! * 100).toStringAsFixed(1)}%',
              ),
            if (trade.graduatedMult != null && trade.graduatedMult != 1.0)
              _detailRow(
                'Graduated Mult',
                '${trade.graduatedMult!.toStringAsFixed(2)}x',
              ),

            // Closed trade details
            if (isClosed) ...[
              const SizedBox(height: 8),
              const Divider(color: Color(0xFF30363D), height: 1),
              const SizedBox(height: 8),
              if (trade.exitDate != null)
                _detailRow('Exit Date', trade.exitDate!),
              if (trade.exitTime != null)
                _detailRow('Exit Time', trade.exitTime!),
              if (trade.exitSpot != null)
                _detailRow('Exit Spot', trade.exitSpot!.toStringAsFixed(2)),
              if (trade.exitReason != null)
                _detailRow(
                  'Exit Reason',
                  _formatExitReason(trade.exitReason!),
                  valueColor: _exitReasonColor(trade.exitReason!),
                ),
              if (trade.realizedPnl != null)
                _detailRow(
                  'Realized P&L',
                  '${trade.realizedPnl! >= 0 ? '+' : ''}${_inrFormatDecimal.format(trade.realizedPnl)}',
                  valueColor: AppTheme.pnlColor(trade.realizedPnl),
                ),
              if (trade.holdingDays != null)
                _detailRow(
                  'Holding Days',
                  '${trade.holdingDays} day${trade.holdingDays! > 1 ? 's' : ''}',
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pnlProgressBar(TradeItem trade) {
    final credit = trade.creditReceived ?? 0;
    if (credit <= 0) return const SizedBox.shrink();
    final currentPnl = trade.currentPnl ?? 0;
    // Progress: 0 = max loss, 1 = full profit (credit kept)
    final progress = (currentPnl / credit).clamp(-1.0, 1.0);
    final normalized = ((progress + 1) / 2).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Profit target',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: AppTheme.pnlColor(currentPnl),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 4,
            child: LinearProgressIndicator(
              value: normalized,
              backgroundColor: AppTheme.loss.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                currentPnl >= 0
                    ? AppTheme.profit.withOpacity(0.7)
                    : AppTheme.loss.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _entryModeBadge(String mode) {
    Color badgeColor;
    String label;
    switch (mode) {
      case 'event_crush':
        badgeColor = const Color(0xFFE8833A);
        label = 'EVENT';
        break;
      case 'vix_harvest':
        badgeColor = const Color(0xFF9B59B6);
        label = 'VIX';
        break;
      default:
        badgeColor = const Color(0xFF58A6FF);
        label = 'STD';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Format large INR amounts compactly: 4,95,000 → ₹4.95L, 12,00,000 → ₹12L
  String _compactInr(double value) {
    final abs = value.abs();
    if (abs >= 1e7) {
      return '\u20B9${(value / 1e7).toStringAsFixed(1)}Cr';
    } else if (abs >= 1e5) {
      final lakhs = value / 1e5;
      return '\u20B9${lakhs.toStringAsFixed(lakhs == lakhs.roundToDouble() ? 0 : 1)}L';
    }
    return _inrFormat.format(value);
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8B949E),
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFFC9D1D9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _dateRange(TradeItem trade) {
    final entry = trade.entryDate ?? trade.date ?? '?';
    final exit = trade.exitDate ?? trade.expiry ?? '?';
    return '$entry  \u2192  $exit';
  }

  String _strikesDisplay(TradeItem trade, bool isIronCondor) {
    if (isIronCondor) {
      final putSell = trade.sellStrike?.toStringAsFixed(0) ?? '?';
      final putBuy = trade.buyStrike?.toStringAsFixed(0) ?? '?';
      final callSell = trade.icCallSell?.toStringAsFixed(0) ?? '?';
      final callBuy = trade.icCallBuy?.toStringAsFixed(0) ?? '?';
      return 'S $putSell / B $putBuy PE  |  S $callSell / B $callBuy CE';
    }
    final sell = trade.sellStrike?.toStringAsFixed(0) ?? '?';
    final buy = trade.buyStrike?.toStringAsFixed(0) ?? '?';
    return 'Sell $sell PE  /  Buy $buy PE';
  }

  String _pnlPctText(TradeItem trade) {
    final pct = trade.currentPnlPct ?? 0;
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}%';
  }

  String _formatExitReason(String reason) {
    return reason
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Color _exitReasonColor(String reason) {
    if (reason.contains('profit') || reason.contains('target')) {
      return AppTheme.profit;
    }
    if (reason.contains('stop') || reason.contains('loss')) {
      return AppTheme.loss;
    }
    if (reason.contains('expiry')) {
      return const Color(0xFFE8833A);
    }
    return const Color(0xFF8B949E);
  }
}
