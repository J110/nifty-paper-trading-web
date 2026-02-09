import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../models/trade.dart';

class PortfolioSummary extends StatelessWidget {
  final Portfolio portfolio;
  final Color accentColor;

  const PortfolioSummary({
    super.key,
    required this.portfolio,
    required this.accentColor,
  });

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
    final pnlColor = AppTheme.pnlColor(portfolio.totalPnl);
    final pnlSign = portfolio.totalPnl >= 0 ? '+' : '';
    final totalCapital = portfolio.deployedCapital + portfolio.availableCapital;
    final deployedFraction =
        totalCapital > 0 ? portfolio.deployedCapital / totalCapital : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Capital flow: Starting -> Current
          Row(
            children: [
              _CapitalLabel(
                label: 'Starting',
                value: _inrFormat.format(portfolio.startingCapital),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.arrow_forward,
                  color: accentColor,
                  size: 18,
                ),
              ),
              _CapitalLabel(
                label: 'Current',
                value: _inrFormat.format(portfolio.currentCapital),
                valueColor: pnlColor,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Total PnL
          Row(
            children: [
              Text(
                'Total P&L',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$pnlSign${_inrFormatDecimal.format(portfolio.totalPnl)}',
                style: TextStyle(
                  color: pnlColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: pnlColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${pnlSign}${portfolio.totalReturnPct.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: pnlColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Deployed vs Available progress bar
          Row(
            children: [
              Text(
                'Deployed',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
              const Spacer(),
              Text(
                'Available',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                value: deployedFraction.clamp(0.0, 1.0),
                backgroundColor: const Color(0xFF238636).withOpacity(0.25),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                _inrFormat.format(portfolio.deployedCapital),
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                _inrFormat.format(portfolio.availableCapital),
                style: const TextStyle(
                  color: Color(0xFF238636),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Summary row: Win Rate | Total Trades | Profit Factor
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _StatItem(
                  label: 'Win Rate',
                  value: '${portfolio.winRate.toStringAsFixed(1)}%',
                  valueColor: portfolio.winRate >= 50
                      ? AppTheme.profit
                      : AppTheme.loss,
                ),
                _verticalDivider(),
                _StatItem(
                  label: 'Total Trades',
                  value: '${portfolio.totalTrades}',
                ),
                _verticalDivider(),
                _StatItem(
                  label: 'Profit Factor',
                  value: portfolio.profitFactor.toStringAsFixed(2),
                  valueColor: portfolio.profitFactor >= 1.0
                      ? AppTheme.profit
                      : AppTheme.loss,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 28,
      color: const Color(0xFF30363D),
    );
  }
}

class _CapitalLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _CapitalLabel({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? const Color(0xFFC9D1D9),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFFC9D1D9),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
