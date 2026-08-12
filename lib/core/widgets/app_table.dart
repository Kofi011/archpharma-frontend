import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppTable extends StatelessWidget {
  final List<String> headers;
  final List<TableRow> rows;
  final Map<int, TableColumnWidth>? columnWidths;

  const AppTable({
    super.key,
    required this.headers,
    required this.rows,
    this.columnWidths,
  });

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: columnWidths,
      border: const TableBorder(
        horizontalInside: BorderSide(color: AppColors.borderLight, width: 0.5),
        bottom: BorderSide(color: AppColors.borderLight, width: 1),
      ),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
          children: headers.map((header) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                header,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            );
          }).toList(),
        ),
        ...rows,
      ],
    );
  }
}
