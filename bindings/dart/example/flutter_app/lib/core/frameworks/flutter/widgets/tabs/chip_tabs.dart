import 'package:flutter/material.dart';

class ChipTabs extends StatelessWidget {
  final TabController controller;
  final List<String> labels;
  final Color backgroundColor;
  final Color indicatorColor;
  final Color labelColor;
  final Color unselectedLabelColor;
  final Color? borderColor;
  final EdgeInsets padding;

  const ChipTabs({
    super.key,
    required this.controller,
    required this.labels,
    required this.backgroundColor,
    required this.indicatorColor,
    required this.labelColor,
    required this.unselectedLabelColor,
    this.borderColor,
    this.padding = const EdgeInsets.all(4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: indicatorColor,
          borderRadius: BorderRadius.circular(999),
        ),
        labelColor: labelColor,
        unselectedLabelColor: unselectedLabelColor,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: labels
            .map((label) => Tab(
                  height: 32,
                  text: label,
                ))
            .toList(),
      ),
    );
  }
}
