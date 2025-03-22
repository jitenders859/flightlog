import 'package:flutter/material.dart';
import 'course_mode.dart';
import 'lms_service.dart';
import 'package:provider/provider.dart';

// import '../flight_logger/constants/colors.dart';
// import '../../../lib/flight_logger/models/course_model.dart';
// import '../../../lib/flight_logger/services/lms_service.dart';
// import '../../../lib/flight_logger/course/course_detail_screen.dart';

class CoursesScreen extends StatefulWidget {
  final bool showOnlyAssigned;

  const CoursesScreen({Key? key, this.showOnlyAssigned = false})
    : super(key: key);

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Course> _courses = [];
  String? _errorMessage;
  String _searchQuery = '';

  // Filter by course category
  final List<String> _categories = ['All', 'PPL', 'CPL', 'Multi', 'Other'];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadCourses();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedCategory = _categories[_tabController.index];
        });
        _filterCourses();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lmsService = Provider.of<LMSService>(context, listen: false);
      List<Course> courses;

      if (widget.showOnlyAssigned) {
        // Get courses assigned to current student
        final authService = Provider.of<AuthService>(context, listen: false);
        final userId = authService.currentUser?.id;

        if (userId != null) {
          courses = await lmsService.getStudentCourses(userId);
        } else {
          throw Exception('User not authenticated');
        }
      } else {
        // Get all courses (for admin/teacher view)
        courses = await lmsService.getCourses();
      }

      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading courses: $e';
        _isLoading = false;
      });
    }
  }

  void _filterCourses() {
    // Filtering is done when displaying, not here
    setState(() {});
  }

  List<Course> get _filteredCourses {
    return _courses.where((course) {
      // Filter by category
      if (_selectedCategory != 'All' && course.category != _selectedCategory) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return course.title.toLowerCase().contains(query) ||
            course.description.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((category) => Tab(text: category)).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CourseSearchDelegate(
                  courses: _courses,
                  onCourseSelected: (course) {
                    // Navigator.of(context).push(
                    //   MaterialPageRoute(
                    //     builder:
                    //         (context) => CourseDetailScreen(course: course),
                    //   ),
                    // );
                  },
                ),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCourses),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadCourses, child: const Text('Retry')),
          ],
        ),
      );
    }

    final filteredCourses = _filteredCourses;

    if (filteredCourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedCategory == 'All'
                  ? 'No courses available'
                  : 'No $_selectedCategory courses available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              widget.showOnlyAssigned
                  ? 'You have not been assigned any courses yet'
                  : 'Start by creating a new course',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredCourses.length,
      itemBuilder: (context, index) {
        final course = filteredCourses[index];
        return _buildCourseCard(course);
      },
    );
  }

  Widget _buildCourseCard(Course course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigator.of(context).push(
          //   MaterialPageRoute(
          //     builder: (context) => CourseDetailScreen(course: course),
          //   ),
          // );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course image or colored header
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: _getCategoryColor(course.category),
                image:
                    course.thumbnailUrl != null
                        ? DecorationImage(
                          image: NetworkImage(course.thumbnailUrl!),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child: Stack(
                children: [
                  // Category badge
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        course.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Course info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Student count chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.people_outline,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${course.assignedStudentIds.length} students',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // View button
                      TextButton(
                        onPressed: () {
                          // Navigator.of(context).push(
                          //   MaterialPageRoute(
                          //     builder:
                          //         (context) =>
                          //             CourseDetailScreen(course: course),
                          //   ),
                          // );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Row(
                          children: [
                            Text('View Course'),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    // Only show FAB for admin/teacher when not filtering by assigned courses
    final authService = Provider.of<AuthService>(context);
    final userRole = authService.currentUser?.role;

    if (!widget.showOnlyAssigned &&
        (userRole == 'admin' || userRole == 'teacher')) {
      return FloatingActionButton(
        onPressed: () {
          // Navigate to create course screen
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateCourseScreen()),
          );
        },
        child: const Icon(Icons.add),
      );
    }

    return null;
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'PPL':
        return Colors.blue;
      case 'CPL':
        return Colors.green;
      case 'Multi':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }
}

class CourseSearchDelegate extends SearchDelegate<Course?> {
  final List<Course> courses;
  final Function(Course) onCourseSelected;

  CourseSearchDelegate({required this.courses, required this.onCourseSelected});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return Center(
        child: Text(
          'Search for courses by title or description',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    final filteredCourses =
        courses.where((course) {
          return course.title.toLowerCase().contains(query.toLowerCase()) ||
              course.description.toLowerCase().contains(query.toLowerCase());
        }).toList();

    if (filteredCourses.isEmpty) {
      return Center(
        child: Text(
          'No results found for "$query"',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredCourses.length,
      itemBuilder: (context, index) {
        final course = filteredCourses[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                course.category == 'PPL'
                    ? Colors.blue
                    : course.category == 'CPL'
                    ? Colors.green
                    : course.category == 'Multi'
                    ? Colors.orange
                    : Colors.purple,
            child: Text(
              course.title[0],
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(course.title),
          subtitle: Text(
            course.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              course.category,
              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
            ),
          ),
          onTap: () {
            close(context, course);
            onCourseSelected(course);
          },
        );
      },
    );
  }
}

// This is a placeholder for imports that would be needed
class CreateCourseScreen extends StatelessWidget {
  const CreateCourseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Course')),
      body: const Center(
        child: Text('Create Course Screen - To be implemented'),
      ),
    );
  }
}

// This is a placeholder for imports that would be needed
class AuthService {
  UserModel? get currentUser => null;
}

// This is a placeholder for imports that would be needed
class UserModel {
  final String id;
  final String role;

  UserModel({required this.id, required this.role});
}
