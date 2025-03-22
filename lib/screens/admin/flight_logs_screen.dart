import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/flight_log_model.dart';
import '../../models/user_model.dart';
import '../student/flight_detail_screen.dart';
import '../../services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';



class FlightLogsScreen extends StatefulWidget {
  const FlightLogsScreen({Key? key}) : super(key: key);

  @override
  State<FlightLogsScreen> createState() => _FlightLogsScreenState();
}

class _FlightLogsScreenState extends State<FlightLogsScreen> {
  List<FlightLogModel> _flightLogs = [];
  Map<String, UserModel?> _userCache = {};
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  
  final TextEditingController _searchController = TextEditingController();
  
  // Filters
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  
  final List<String> _statusOptions = [
    'All',
    'in-progress',
    'completed',
    'cancelled',
  ];
  
  @override
  void initState() {
    super.initState();
    _loadFlightLogs();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadFlightLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // TODO: Implement getting all flight logs once we have that method
      // For now we'll simulate some data
      _flightLogs = [];
      
      // Cache user data for all students in the flight logs
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      
      for (var flightLog in _flightLogs) {
        if (!_userCache.containsKey(flightLog.studentId)) {
          _userCache[flightLog.studentId] = await databaseService.getUser(flightLog.studentId);
        }
        
        if (flightLog.teacherId != null && !_userCache.containsKey(flightLog.teacherId!)) {
          _userCache[flightLog.teacherId!] = await databaseService.getUser(flightLog.teacherId!);
        }
      }
    } catch (e) {
      _errorMessage = 'Error loading flight logs: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  List<FlightLogModel> get _filteredFlightLogs {
    return _flightLogs.where((flightLog) {
      // Apply status filter
      if (_selectedStatus != null && _selectedStatus != 'All' && flightLog.status != _selectedStatus) {
        return false;
      }
      
      // Apply date filters
      if (_startDate != null && flightLog.startTime.isBefore(_startDate!)) {
        return false;
      }
      
      if (_endDate != null) {
        final endDatePlusOneDay = _endDate!.add(const Duration(days: 1));
        if (flightLog.startTime.isAfter(endDatePlusOneDay)) {
          return false;
        }
      }
      
      // Apply search query
      if (_searchQuery.isNotEmpty) {
        final student = _userCache[flightLog.studentId];
        final teacher = flightLog.teacherId != null ? _userCache[flightLog.teacherId!] : null;
        
        final String studentName = student?.fullName.toLowerCase() ?? '';
        final String teacherName = teacher?.fullName.toLowerCase() ?? '';
        
        return studentName.contains(_searchQuery.toLowerCase()) ||
               teacherName.contains(_searchQuery.toLowerCase()) ||
               flightLog.id.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      
      return true;
    }).toList();
  }
  
  void _showDatePicker(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _startDate ?? DateTime.now().subtract(const Duration(days: 30))
          : _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.adminColor,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          
          // If end date is before start date, update end date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          
          // If start date is after end date, update start date
          if (_startDate != null && _startDate!.isAfter(_endDate!)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }
  
  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _startDate = null;
      _endDate = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flight Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFlightLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by student or teacher name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Status filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.backgroundDark),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus ?? 'All',
                      hint: const Text('Status'),
                      icon: const Icon(Icons.arrow_drop_down),
                      style: const TextStyle(color: AppColors.textPrimary),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedStatus = newValue != 'All' ? newValue : null;
                        });
                      },
                      items: _statusOptions.map<DropdownMenuItem<String>>(
                        (String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value == 'All' ? 'All Statuses' : 
                              value.substring(0, 1).toUpperCase() + value.substring(1),
                            ),
                          );
                        }
                      ).toList(),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Start date filter
                InkWell(
                  onTap: () => _showDatePicker(true),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.backgroundDark),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _startDate != null
                              ? 'From: ${DateFormat('MMM dd, yyyy').format(_startDate!)}'
                              : 'Start Date',
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // End date filter
                InkWell(
                  onTap: () => _showDatePicker(false),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.backgroundDark),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _endDate != null
                              ? 'To: ${DateFormat('MMM dd, yyyy').format(_endDate!)}'
                              : 'End Date',
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Clear filters button
                if (_selectedStatus != null || _startDate != null || _endDate != null || _searchQuery.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear Filters'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.adminColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.adminColor.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.adminColor),
                const SizedBox(width: 8),
                Text(
                  'Displaying ${_filteredFlightLogs.length} of ${_flightLogs.length} flight logs',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.adminColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Flight logs list
          Expanded(
            child: _buildFlightLogs(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFlightLogs() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadFlightLogs,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_flightLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flight_takeoff,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Flight Logs Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'There are no flight logs in the system yet.',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    final filteredLogs = _filteredFlightLogs;
    
    if (filteredLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Matching Flight Logs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your search filters.',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminColor,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredLogs.length,
      itemBuilder: (context, index) {
        final flightLog = filteredLogs[index];
        final student = _userCache[flightLog.studentId];
        final teacher = flightLog.teacherId != null ? _userCache[flightLog.teacherId!] : null;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FlightDetailScreen(
                    flightLogId: flightLog.id,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with date and status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMM dd, yyyy • HH:mm').format(flightLog.startTime),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      _buildStatusBadge(flightLog.status),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Student info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.studentColor,
                        child: Text(
                          student != null
                              ? student.firstName[0] + student.lastName[0]
                              : '??',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.school, size: 16, color: AppColors.studentColor),
                                const SizedBox(width: 4),
                                const Text(
                                  'Student:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              student?.fullName ?? 'Unknown Student',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (teacher != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 16, color: AppColors.teacherColor),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Teacher:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                teacher.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  
                  // Flight stats
                  Row(
                    children: [
                      _buildFlightStatItem(
                        icon: Icons.timer,
                        title: 'Duration',
                        value: flightLog.durationString,
                      ),
                      const SizedBox(width: 24),
                      _buildFlightStatItem(
                        icon: Icons.place,
                        title: 'Location Points',
                        value: '${flightLog.flightPath.length}',
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FlightDetailScreen(
                                  flightLogId: flightLog.id,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('View'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.adminColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'in-progress':
        color = AppColors.warning;
        text = 'In Progress';
        break;
      case 'completed':
        color = AppColors.success;
        text = 'Completed';
        break;
      case 'cancelled':
        color = AppColors.error;
        text = 'Cancelled';
        break;
      default:
        color = AppColors.textSecondary;
        text = status.substring(0, 1).toUpperCase() + status.substring(1);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFlightStatItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}