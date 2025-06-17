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

  static final List<Widget> _pages = const <Widget>[
    ContactAndGroupWidget(),
    ChatbotScreen(),
    ProfileWidget(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), label: 'Chat'),
    BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'Gemini'),
    BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4A44A),
        title: const Text(
          'blaabber',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFF4A44A),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Color(0xFFFFF4E5),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: _navItems,
      ),
    );
  }
}
