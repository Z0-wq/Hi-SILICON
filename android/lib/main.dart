import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'theme.dart';
import 'screens/sport_tab/sport_screen.dart';
import 'screens/data_tab/data_screen.dart';
import 'screens/mine_tab/mine_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const KeepFitApp(),
    ),
  );
}

class KeepFitApp extends StatelessWidget {
  const KeepFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '运动',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _pages = [
    SportScreen(),
    DataScreen(),
    MineScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run),
            label: '运动',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '数据',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
