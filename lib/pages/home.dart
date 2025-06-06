import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/pages/chatbot_screen.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/contact_group_widget.dart';
import 'package:fp_kelompok_1_ppb_c/widgets/profile/profile_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    Center(child: Text('Personal Chat', style: TextStyle(fontSize: 24))),
    Center(child: Text('Group Chat', style: TextStyle(fontSize: 24))),
    Center(child: ChatbotScreen()),
    ContactAndGroupWidget(),
    ProfileWidget(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Personal'),
    BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Group'),
    BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'Gemini'),
    BottomNavigationBarItem(icon: Icon(Icons.contacts), label: 'Contacts'),
    BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat App'), centerTitle: true),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: _navItems,
      ),
    );
  }
}
