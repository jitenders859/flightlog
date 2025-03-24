// lib/screens/student/flight_detail_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/flight_overview_model.dart';

class FlightOverviewDetailDialog extends StatelessWidget {
  final FlightOverviewModel flight;

  const FlightOverviewDetailDialog({Key? key, required this.flight})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    final DateFormat timeFormat = DateFormat('HH:mm');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Flight Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Info Section
                  _buildSectionTitle('Flight Information'),
                  const SizedBox(height: 16),

                  // Two column layout for details
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailItem(
                              'Date',
                              dateFormat.format(flight.startTime),
                            ),
                            _buildDetailItem(
                              'Time',
                              '${timeFormat.format(flight.startTime)} - ${timeFormat.format(flight.endTime)}',
                            ),
                            _buildDetailItem('Type', flight.type),
                            _buildDetailItem('Program', flight.program),
                          ],
                        ),
                      ),

                      // Right column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailItem('Aircraft', flight.aircraft),
                            _buildDetailItem('Instructor', flight.instructor),
                            _buildDetailItem('Student', flight.student),
                            _buildDetailItem(
                              'Status',
                              flight.status,
                              valueColor:
                                  flight.status == 'CANCELED'
                                      ? Colors.red
                                      : flight.status == 'COMPLETED'
                                      ? Colors.green
                                      : Colors.blue,
                              valueBold: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Cancellation Details (if applicable)
                  if (flight.status == 'CANCELED') ...[
                    _buildSectionTitle('Cancellation Information'),
                    const SizedBox(height: 16),
                    _buildDetailItem(
                      'Reason',
                      flight.cancelReason.isEmpty
                          ? 'See evaluation'
                          : flight.cancelReason,
                    ),
                    _buildDetailItem('Evaluation', flight.evaluation),
                  ],

                  const SizedBox(height: 24),

                  // Flight Details Section
                  _buildSectionTitle('Flight Details'),
                  const SizedBox(height: 16),

                  // Two column layout for flight details
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailItem('Flight Time', flight.flight),
                            _buildDetailItem('Air Time', flight.air),
                            _buildDetailItem('Briefing', flight.briefing),
                          ],
                        ),
                      ),

                      // Right column
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Add any additional flight details here
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.blue, width: 2)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
