import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../home/presentation/widgets/home_feature_icon.dart';
import '../../data/models/membership_package_model.dart';

class MembershipComparison extends StatefulWidget {
  const MembershipComparison({super.key, required this.packages});
  final List<MembershipPackage> packages;

  @override
  State<MembershipComparison> createState() => _MembershipComparisonState();
}

class _MembershipComparisonState extends State<MembershipComparison> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Widget _cell(String text, {bool heading = false}) => Padding(
    padding: const EdgeInsets.all(18),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        height: 1.5,
        fontWeight: heading ? FontWeight.w600 : FontWeight.w400,
        color: heading ? const Color(0xFF38291F) : const Color(0xFF8A7464),
      ),
    ),
  );

  TableRow _row(String title, List<String> values, {bool shaded = false}) =>
      TableRow(
        decoration: BoxDecoration(
          color: shaded ? const Color(0xFFFCFAF7) : Colors.white,
        ),
        children: [
          _cell(title, heading: true),
          for (final value in values) _cell(value),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final packages = widget.packages;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEDFD1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minimumWidth = 160.0 + packages.length * 200;
          final width = constraints.maxWidth > minimumWidth
              ? constraints.maxWidth
              : minimumWidth;
          return Scrollbar(
            controller: _scroll,
            thumbVisibility: true,
            child: SingleChildScrollView(
              key: const ValueKey('membership-comparison-scroll'),
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: width,
                child: Table(
                  defaultColumnWidth: const FlexColumnWidth(),
                  columnWidths: const {0: FixedColumnWidth(160)},
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: Color(0xFFF0E7DD)),
                  ),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFFFF5E9)),
                      children: [
                        _cell('Quyền lợi', heading: true),
                        for (final package in packages)
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                HomeFeatureIcon(
                                  icon: package.price == 0
                                      ? Symbols.home_work
                                      : package.vipPostQuota > 0
                                      ? Symbols.payments
                                      : Symbols.assignment,
                                  size: 48,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  package.packageName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF38291F),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  package.price == 0
                                      ? 'Miễn phí'
                                      : '${NumberFormat.decimalPattern('vi_VN').format(package.price)} đ',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFD76B28),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    _row('Tin đăng thường', [
                      for (final p in packages) '${p.standardPostQuota} tin',
                    ]),
                    _row('Tin đăng VIP', [
                      for (final p in packages)
                        p.vipPostQuota == 0
                            ? 'Không bao gồm'
                            : '${p.vipPostQuota} tin',
                    ], shaded: true),
                    _row('Làm mới tin', [
                      for (final p in packages)
                        p.refreshQuota == 0
                            ? 'Không bao gồm'
                            : '${p.refreshQuota} lượt',
                    ]),
                    if (packages.any((p) => p.description?.isNotEmpty == true))
                      _row('Thông tin thêm', [
                        for (final p in packages)
                          p.description?.isNotEmpty == true
                              ? p.description!
                              : '—',
                      ], shaded: true),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
