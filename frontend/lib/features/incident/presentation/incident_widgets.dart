import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/incident_repository.dart';

String incidentDate(DateTime value) =>
    DateFormat('dd/MM/yyyy HH:mm').format(value);

class IncidentStatus extends StatelessWidget {
  const IncidentStatus(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'IN_PROGRESS':
        color = const Color(0xFF397AC0);
        break;
      case 'RESOLVED':
        color = const Color(0xFF298774);
        break;
      case 'REJECTED':
        color = const Color(0xFFB34F4F);
        break;
      default:
        color = const Color(0xFFB58131);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        incidentStatuses[status] ?? status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class IncidentPanel extends StatelessWidget {
  const IncidentPanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: .15),
      ),
    ),
    child: child,
  );
}

InputDecoration incidentInput(String label) => InputDecoration(
  labelText: label,
  alignLabelWithHint: true,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  contentPadding: const EdgeInsets.all(16),
);
