
import 'package:flutter/material.dart';

class LifeMateBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const LifeMateBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  static const List<IconData> icons = [
    Icons.home_outlined,
    Icons.check_circle_outline,
    Icons.arrow_downward,
    Icons.arrow_upward,
    Icons.note_alt_outlined,
    Icons.more_horiz,
  ];

  static const List<String> labels = [
    'Home',
    'To-Do',
    'Income',
    'Expense',
    'Notes',
    'More',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 61,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(.5),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: List.generate(6, (index) {
            final selected = selectedIndex == index;
            final color = selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey;

            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icons[index],
                        size: 21,
                        color: color,
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          labels[index],
                          style: TextStyle(
                            fontSize: 9,
                            color: color,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
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
    );
  }
}
