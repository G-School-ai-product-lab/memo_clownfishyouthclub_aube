import 'package:flutter/material.dart';
import '../../../memo/domain/entities/folder.dart';

class FolderListItem extends StatelessWidget {
  final Folder folder;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const FolderListItem({
    super.key,
    required this.folder,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFFFF5F5) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isSelected ? const Color(0xFF8B3A3A) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              // 폴더 아이콘
              Text(
                folder.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              // 폴더명
              Expanded(
                child: Text(
                  folder.name,
                  style: TextStyle(
                    fontSize: 15,
                    color: isSelected ? const Color(0xFF8B3A3A) : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 메모 개수
              if (folder.memoCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF8B3A3A)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${folder.memoCount}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
