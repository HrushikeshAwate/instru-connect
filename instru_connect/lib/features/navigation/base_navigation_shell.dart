import 'package:flutter/material.dart';

class BaseNavigationShell extends StatefulWidget {
  final List<Widget> screens;
  final List<BottomNavigationBarItem> items;

  const BaseNavigationShell({
    super.key,
    required this.screens,
    required this.items,
  });

  @override
  State<BaseNavigationShell> createState() => _BaseNavigationShellState();
}

class _BaseNavigationShellState extends State<BaseNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: widget.screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: widget.items,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
