// lib/screens/student/flight_detail_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:navlog/models/student_scedule.dart';
import '../../constants/colors.dart';

class FlightDetailDialog extends StatelessWidget {
  final ScheduleEvent event;

  const FlightDetailDialog({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(08),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Text(
              'Flight Detail',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Basic Information Section
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  child: const Text(
                    'Basic Information',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Details Grid
                _buildDetailRow('Status:', event.status, null),
                _buildDetailRow('Aircraft:', event.aircraft, 'Campus'),
                _buildDetailRow('Instructor:', event.instructor, 'Student:'),
                _buildDetailRow(
                  'Start:',
                  DateFormat('MM/dd HH:mm').format(event.startTime),
                  'End:',
                  DateFormat('MM/dd HH:mm').format(event.endTime),
                ),
                _buildDetailRow(
                  'Remark:',
                  'N/A',
                  'Created by',
                  'E-ICA-DISPATCHER3 at ${DateFormat('MM/dd HH:mm').format(DateTime.now().subtract(const Duration(days: 5)))}',
                ),
              ],
            ),
          ),

          // Flight Data Section
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  child: const Text(
                    'Flight Data',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Flight Data Grid
                _buildDetailRow('Type:', 'DUAL', 'Program:', 'PPL'),
                _buildDetailRow('Content:', 'N/A', 'Status:', 'N/A'),
                _buildDetailRow('Exercise:', 'N/A', 'Night Flight:', 'N/A'),
                _buildDetailRow('Weight:', 'N/A lb', 'Fuel:', 'N/A gal'),
                _buildDetailRow('CX:', 'N/A', 'cx Time:', 'N/A h'),
                _buildDetailRow('Route:', 'N/A', 'ETA:', 'N/A'),
                _buildDetailRow(
                  'Instrument Time:',
                  'N/A h',
                  'Ground Briefing Flight:',
                  'N/A h',
                ),
                _buildDetailRow('Hobbs Start:', 'N/A', 'Hobbs Stop:', 'N/A'),
                _buildDetailRow('Engine Start:', 'N/A', 'Air Up:', 'N/A'),
                _buildDetailRow('Engine Off:', 'N/A', 'Air Down:', 'N/A'),
                _buildDetailRow('Flight Time', 'N/A h', 'Air Time', 'N/A h'),
                _buildDetailRow('Student Note:', 'N/A', null, null),
                _buildDetailRow('Instructor Note:', 'N/A', null, null),
              ],
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ongoing',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label1,
    String value1,
    String? label2, [
    String? value2,
  ]) {
    TextStyle _getTextStyle(String label) {
      return TextStyle(
        fontWeight: label == 'Status:' ? FontWeight.bold : FontWeight.normal,
        color: label == 'Status:' ? Colors.blue : null,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First label and value
                Text(label1, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value1, style: _getTextStyle(label1)),
              ],
            ),
          ),

          // Optional second label and value
          if (label2 != null && value2 != null) ...{
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(label2, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(value2, style: _getTextStyle(label2)),
                ],
              ),
            ),
          },
        ],
      ),
    );
  }
}
