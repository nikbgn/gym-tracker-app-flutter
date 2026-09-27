import 'package:flutter/material.dart';

import '../app_controller.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'templates_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        controller: widget.controller,
        onOpenTemplates: () => _selectTab(1),
        onOpenHistory: () => _selectTab(2),
      ),
      TemplatesScreen(
        controller: widget.controller,
        onOpenHistory: () => _selectTab(2),
      ),
      HistoryScreen(controller: widget.controller),
      LibraryScreen(controller: widget.controller),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_list_outlined),
            selectedIcon: Icon(Icons.view_list_rounded),
            label: 'Templates',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Manage',
          ),
        ],
      ),
    );
  }

  void _selectTab(int index) => setState(() => _selectedIndex = index);
}
