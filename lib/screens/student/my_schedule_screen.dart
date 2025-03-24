// lib/screens/student/my_schedule_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:navlog/dialog_components/flight_scedule_detail_dialog.dart.dart';
import 'package:navlog/models/student_scedule.dart';
import 'package:provider/provider.dart';
import '../../../providers/schedule_provider.dart';
import '../../../services/auth_service.dart';
import '../../../constants/colors.dart';
import '../../../widgets/custom_button.dart';

class MyScheduleScreen extends StatefulWidget {
  const MyScheduleScreen({Key? key}) : super(key: key);

  @override
  State<MyScheduleScreen> createState() => _MyScheduleScreenState();
}

class _MyScheduleScreenState extends State<MyScheduleScreen> {
  final DateFormat _headerDateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _dayFormat = DateFormat('EEE');
  final DateFormat _dateFormat = DateFormat('MMM dd');
  final DateFormat _timeFormat = DateFormat('h:mm a');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final scheduleProvider = Provider.of<ScheduleProvider>(
        context,
        listen: false,
      );

      if (authService.currentUser != null) {
        scheduleProvider.initialize(authService.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final scheduleProvider = Provider.of<ScheduleProvider>(context);
    final mediaQuery = MediaQuery.of(context);
    final studentId = authService.currentUser?.id ?? '';

    return scheduleProvider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
          children: [
            _buildHeader(scheduleProvider, studentId),
            _buildViewToggle(scheduleProvider),
            const SizedBox(height: 8),
            scheduleProvider.isWeekView
                ? _buildWeekView(scheduleProvider, mediaQuery)
                : _buildDayView(scheduleProvider, mediaQuery),
          ],
        );
  }

  Widget _buildHeader(ScheduleProvider provider, String studentId) {
    String title =
        provider.isWeekView
            ? 'Week of ${_dateFormat.format(provider.weekStartDate)} - ${_dateFormat.format(provider.weekStartDate.add(const Duration(days: 6)))}'
            : _headerDateFormat.format(provider.selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              if (provider.isWeekView) {
                provider.previousWeek(studentId);
              } else {
                provider.previousDay(studentId);
              }
            },
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              if (provider.isWeekView) {
                provider.nextWeek(studentId);
              } else {
                provider.nextDay(studentId);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(ScheduleProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ToggleButtons(
          isSelected: [provider.isWeekView, !provider.isWeekView],
          onPressed: (index) {
            provider.toggleView();
          },
          borderRadius: BorderRadius.circular(30),
          selectedColor: Colors.white,
          fillColor: AppColors.primary,
          color: AppColors.primary,
          constraints: const BoxConstraints(minWidth: 100, minHeight: 36),
          children: const [Text('Week'), Text('Day')],
        ),
      ],
    );
  }

  Widget _buildWeekView(ScheduleProvider provider, MediaQueryData mediaQuery) {
    // Calculate the start of the week (Sunday)
    final weekStart = provider.weekStartDate;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Days header
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: List.generate(7, (index) {
                    final day = weekStart.add(Duration(days: index));
                    final isToday = _isSameDay(day, DateTime.now());

                    return Expanded(
                      child: InkWell(
                        onTap: () {
                          final authService = Provider.of<AuthService>(
                            context,
                            listen: false,
                          );
                          final studentId = authService.currentUser?.id ?? '';
                          provider.selectDate(studentId, day);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                isToday
                                    ? AppColors.primary.withOpacity(0.1)
                                    : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _dayFormat.format(day),
                                style: TextStyle(
                                  fontWeight:
                                      isToday
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color:
                                      isToday
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                day.day.toString(),
                                style: TextStyle(
                                  fontWeight:
                                      isToday
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color:
                                      isToday
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Time slots grid
              Container(
                height:
                    mediaQuery.size.height -
                    220, // Adjust based on your app's layout
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(7, (dayIndex) {
                    final day = weekStart.add(Duration(days: dayIndex));
                    final dayEvents = provider.getEventsForDay(day);

                    return Expanded(
                      child: Column(
                        children: [
                          // Render events for this day
                          ...dayEvents.map(
                            (event) => _buildEventCard(event, provider),
                          ),

                          // Empty space if no events
                          if (dayEvents.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: const Text(
                                '---',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayView(ScheduleProvider provider, MediaQueryData mediaQuery) {
    final timeSlots = List.generate(18, (index) => index + 6); // 6 AM to 11 PM
    final dayEvents = provider.getEventsForDay(provider.selectedDate);

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Today's date header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                DateFormat('EEEE, MMMM d, yyyy').format(provider.selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Time slots with events
            ...timeSlots.map((hour) {
              // Find events that start in this hour
              final hourEvents =
                  dayEvents
                      .where((event) => event.startTime.hour == hour)
                      .toList();

              return Column(
                children: [
                  _buildTimeSlotHeader(hour),
                  ...hourEvents.map(
                    (event) => _buildEventCard(event, provider),
                  ),
                  if (hourEvents.isEmpty) const SizedBox(height: 8),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotHeader(int hour) {
    // Format time (convert 24h to 12h format with AM/PM)
    final formattedHour =
        hour > 12
            ? '${hour - 12} PM'
            : hour == 12
            ? '12 PM'
            : '$hour AM';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        formattedHour,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildEventCard(ScheduleEvent event, ScheduleProvider provider) {
    final Color statusColor = _getStatusColor(event.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: statusColor, width: 1),
      ),
      child: InkWell(
        onTap: () {
          _showEventDetails(event);
        },
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${_timeFormat.format(event.startTime)} - ${_timeFormat.format(event.endTime)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if (event.instructor.isNotEmpty || event.aircraft.isNotEmpty)
                const SizedBox(height: 4),
              if (event.instructor.isNotEmpty)
                Text(
                  'Inst: ${event.instructor}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              if (event.aircraft.isNotEmpty)
                Text(
                  'Aircraft: ${event.aircraft}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEventDetails(ScheduleEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and status
                Row(
                  children: [Expanded(child: FlightDetailDialog(event: event))],
                ),

                const SizedBox(height: 24),

                // Actions
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.start,
                //   children: [
                //     Expanded(
                //       child: CustomButton(
                //         text: 'Close',
                //         isOutlined: true,
                //         icon: Icons.close,
                //         onPressed: () => Navigator.pop(context),
                //       ),
                //     ),

                //     if (event.status == 'OPEN') const SizedBox(width: 10),
                //     Expanded(
                //       child: CustomButton(
                //         text: 'Check In',
                //         icon: Icons.check_circle,
                //         onPressed: () {
                //           Navigator.pop(context);
                //           // Handle check-in logic
                //         },
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DONE':
        return Colors.green;
      case 'OPEN':
        return AppColors.primary;
      case 'CANCELED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
