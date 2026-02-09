import 'package:flutter/material.dart';

import '../../../models/trade.dart';
import 'trade_card.dart';

enum TradeFilter { all, winners, losers }

enum TradeSort { date, pnl, duration }

class TradeList extends StatefulWidget {
  final List<TradeItem> trades;
  final bool isOpen;

  const TradeList({
    super.key,
    required this.trades,
    this.isOpen = false,
  });

  @override
  State<TradeList> createState() => _TradeListState();
}

class _TradeListState extends State<TradeList> {
  TradeFilter _filter = TradeFilter.all;
  TradeSort _sort = TradeSort.date;
  bool _sortAscending = false;

  List<TradeItem> get _filteredSorted {
    var list = List<TradeItem>.from(widget.trades);

    // Apply filter
    switch (_filter) {
      case TradeFilter.winners:
        list = list.where((t) => t.pnl > 0).toList();
        break;
      case TradeFilter.losers:
        list = list.where((t) => t.pnl <= 0).toList();
        break;
      case TradeFilter.all:
        break;
    }

    // Apply sort
    list.sort((a, b) {
      int cmp;
      switch (_sort) {
        case TradeSort.date:
          final aDate = a.entryDate ?? a.date ?? '';
          final bDate = b.entryDate ?? b.date ?? '';
          cmp = aDate.compareTo(bDate);
          break;
        case TradeSort.pnl:
          cmp = a.pnl.compareTo(b.pnl);
          break;
        case TradeSort.duration:
          cmp = (a.holdingDays ?? 0).compareTo(b.holdingDays ?? 0);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSorted;

    return Column(
      children: [
        // Filter and sort controls
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              // Filter chips
              _FilterChip(
                label: 'All',
                selected: _filter == TradeFilter.all,
                onTap: () => setState(() => _filter = TradeFilter.all),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Winners',
                selected: _filter == TradeFilter.winners,
                selectedColor: const Color(0xFF50C878),
                onTap: () => setState(() => _filter = TradeFilter.winners),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Losers',
                selected: _filter == TradeFilter.losers,
                selectedColor: const Color(0xFFE5534B),
                onTap: () => setState(() => _filter = TradeFilter.losers),
              ),
              const Spacer(),
              // Sort dropdown
              PopupMenuButton<TradeSort>(
                onSelected: (val) {
                  setState(() {
                    if (_sort == val) {
                      _sortAscending = !_sortAscending;
                    } else {
                      _sort = val;
                      _sortAscending = false;
                    }
                  });
                },
                itemBuilder: (context) => [
                  _sortMenuItem(TradeSort.date, 'Date'),
                  _sortMenuItem(TradeSort.pnl, 'P&L'),
                  _sortMenuItem(TradeSort.duration, 'Duration'),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _sortLabel(),
                        style: const TextStyle(
                          color: Color(0xFF8B949E),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: const Color(0xFF8B949E),
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Count label
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${filtered.length} trade${filtered.length != 1 ? 's' : ''}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          ),
        ),

        // Trade cards list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No trades match filter',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return TradeCard(trade: filtered[index]);
                  },
                ),
        ),
      ],
    );
  }

  String _sortLabel() {
    switch (_sort) {
      case TradeSort.date:
        return 'Date';
      case TradeSort.pnl:
        return 'P&L';
      case TradeSort.duration:
        return 'Duration';
    }
  }

  PopupMenuItem<TradeSort> _sortMenuItem(TradeSort sort, String label) {
    final isActive = _sort == sort;
    return PopupMenuItem<TradeSort>(
      value: sort,
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? const Color(0xFF58A6FF)
                  : const Color(0xFFC9D1D9),
              fontSize: 13,
            ),
          ),
          if (isActive) ...[
            const Spacer(),
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: const Color(0xFF58A6FF),
              size: 14,
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? selectedColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? const Color(0xFF58A6FF);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color.withOpacity(0.5) : const Color(0xFF30363D),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : const Color(0xFF8B949E),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
