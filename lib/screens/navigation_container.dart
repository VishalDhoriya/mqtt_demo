import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import 'host_session_screen.dart';
import 'logs_page.dart';

class NavigationContainer extends StatefulWidget {
  final MqttService mqttService;
  final VoidCallback onBackToHome;

  const NavigationContainer({
    super.key,
    required this.mqttService,
    required this.onBackToHome,
  });

  @override
  State<NavigationContainer> createState() => _NavigationContainerState();
}

class _NavigationContainerState extends State<NavigationContainer> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HostSessionScreen(
        mqttService: widget.mqttService,
        onBackToHome: widget.onBackToHome,
        showMessageLog: false,
      ),
      LogsPage(
        mqttService: widget.mqttService,
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: _pages[_selectedIndex],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: BottomNavigationBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.devices_outlined),
                  activeIcon: Icon(Icons.devices),
                  label: 'Session',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  activeIcon: Icon(Icons.chat_bubble),
                  label: 'Messages',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.grey.shade600,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 11,
              ),
              type: BottomNavigationBarType.fixed,
              showUnselectedLabels: true,
              onTap: _onItemTapped,
            ),
          ),
        ],
      ),
    );
  }
}
