import 'package:flutter/material.dart';
import 'course_mode.dart';

class CourseCardWidget extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onAssignStudents;
  final bool isEditable;
  final bool showStudentCount;
  final bool showContentCount;
  final int contentCount;

  const CourseCardWidget({
    Key? key,
    required this.course,
    this.onTap,
    this.onEdit,
    this.onAssignStudents,
    this.isEditable = false,
    this.showStudentCount = true,
    this.showContentCount = false,
    this.contentCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course image or colored header
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(course.category),
                    image: course.thumbnailUrl != null
                        ? DecorationImage(
                            image: NetworkImage(course.thumbnailUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),
                
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
                
                // Edit button
                if (isEditable) ...[
                  Positioned(
                    top: 12,
                    right: 12,
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.7),
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        color: Colors.black,
                        onPressed: onEdit,
                        tooltip: 'Edit Course',
                      ),
                    ),
                  ),
                ],
              ],
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
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Student count chip
                      if (showStudentCount) ...[
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
                      ],
                      
                      // Content count chip
                      if (showContentCount) ...[
                        if (showStudentCount) const SizedBox(width: 8),
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
                                Icons.video_library,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$contentCount items',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const Spacer(),
                      
                      // Assign students button
                      if (isEditable && onAssignStudents != null) ...[
                        TextButton.icon(
                          onPressed: onAssignStudents,
                          icon: const Icon(Icons.person_add, size: 16),
                          label: const Text('Assign'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ] else ...[
                        // View button
                        TextButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('View'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
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