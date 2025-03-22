import 'package:flutter/material.dart';
import 'content_model.dart';

class ContentItemWidget extends StatelessWidget {
  final Content content;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isEditable;

  const ContentItemWidget({
    Key? key,
    required this.content,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isEditable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine icon and color based on content type
    IconData iconData;
    Color iconColor;
    
    switch (content.contentType) {
      case ContentType.video:
        iconData = Icons.play_circle_outline;
        iconColor = Colors.red;
        break;
      case ContentType.document:
        iconData = Icons.description_outlined;
        iconColor = Colors.blue;
        break;
      case ContentType.pdf:
        iconData = Icons.picture_as_pdf_outlined;
        iconColor = Colors.red;
        break;
      case ContentType.quiz:
        iconData = Icons.quiz_outlined;
        iconColor = Colors.orange;
        break;
      case ContentType.test:
        iconData = Icons.assignment_outlined;
        iconColor = Colors.purple;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Content type icon
              CircleAvatar(
                backgroundColor: iconColor.withOpacity(0.1),
                child: Icon(iconData, color: iconColor),
              ),
              
              const SizedBox(width: 16),
              
              // Content details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (content.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        content.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Edit/Delete buttons if editable
              if (isEditable) ...[
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ] else ...[
                // Forward arrow
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}