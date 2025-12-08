import 'package:flutter/material.dart';
import '../../../memo/domain/entities/tag.dart';

class TagListItem extends StatelessWidget {
  final Tag tag;
  final bool isSelected;
  final VoidCallback onTap;

  const TagListItem({
    super.key,
    required this.tag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFFFF5F5) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
              // # 기호
              Text(
                '#',
                style: TextStyle(
                  fontSize: 18,
                  color: isSelected ? const Color(0xFF8B3A3A) : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              // 태그명
              Expanded(
                child: Text(
                  tag.name,
                  style: TextStyle(
                    fontSize: 15,
                    color: isSelected ? const Color(0xFF8B3A3A) : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 메모 개수
              if (tag.memoCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF8B3A3A)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tag.memoCount}',
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
