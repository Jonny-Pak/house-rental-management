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
      borderRadius: BorderRadius.circular(24),
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
  filled: true,
  fillColor: const Color(0x087A91A8),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: Color(0x407A91A8)),
  ),
  contentPadding: const EdgeInsets.all(16),
);

class IncidentHeader extends StatelessWidget {
  const IncidentHeader({
    super.key,
    required this.title,
    required this.description,
  });
  final String title, description;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF24484B), Color(0xFF163336)],
      ),
      borderRadius: BorderRadius.circular(26),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE8CD),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.support_agent_rounded,
            color: Color(0xFFA56A38),
            size: 30,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: const TextStyle(color: Color(0xFFD8E9E6), height: 1.6),
        ),
      ],
    ),
  );
}
