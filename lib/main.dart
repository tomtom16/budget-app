import 'package:budget_app/views/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'enums/enums.dart';
import 'views/add_entry_view.dart';
import 'views/dashboard.dart';
import 'views/detail_dashboard.dart';
import 'views/generic_view.dart';
import 'views/transactions.dart';
import 'views/trends.dart';
import 'widgets/sidebar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget App',
      theme: ThemeData.light(),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isAuthenticated = false;
  AppPage _selectedPage = AppPage.dashboard;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final FlutterSecureStorage _storage = FlutterSecureStorage();

  void _onLoginSuccess() {
    setState(() => _isAuthenticated = true);
  }

  Widget _getView(AppPage page) {
    switch (page) {
      case AppPage.login:
        return LoginPage(onLoginSuccess: _onLoginSuccess, storage: _storage);
      case AppPage.details:
        return DetailDashboard();
      case AppPage.trends:
        return BarChartView();
      case AppPage.transactions:
        return TransactionsView();
      case AppPage.add:
        return AddEntryView(
          onSubmitted: () {
            setState(() => _selectedPage = AppPage.transactions);
          },
        );
      case AppPage.settings:
        return GenericView('Settings');
      case AppPage.dashboard:
      default:
        return DashboardView();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 600;

          return Scaffold(
            key: _scaffoldKey,
            appBar: isMobile
                ? AppBar(
                    title: Text('Budget App'),
                    leading: IconButton(
                      icon: Icon(Icons.menu),
                      onPressed: () {
                        if (_scaffoldKey.currentState?.hasDrawer ?? false) {
                          _scaffoldKey.currentState!.openDrawer();
                        }
                      },
                    ),
                  )
                : null,
            drawer: isMobile
                ? Drawer(
                    child: Sidebar(
                      isAuthenticated: _isAuthenticated,
                      selectedPage: _selectedPage,
                      onPageSelected: (page) {
                        setState(() => _selectedPage = page);
                        Navigator.of(context).pop(); // close drawer
                      },
                      isMobile: isMobile,
                    ),
                  )
                : null,
            body: SafeArea(
              child: Row(
                children: [
                  if (!isMobile)
                    Sidebar(
                      isAuthenticated: _isAuthenticated,
                      selectedPage: _selectedPage,
                      onPageSelected: (page) {
                        setState(() => _selectedPage = page);
                      },
                      isMobile: isMobile,
                    ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: KeyedSubtree(
                        key: ValueKey(_selectedPage),
                        child: _getView(_selectedPage),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      return MaterialApp(
        title: "Flutter Protected App",
        theme: ThemeData(
          useMaterial3: true, // ✅ Enables Material 3
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          textTheme: TextTheme(
            headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            bodyMedium: TextStyle(fontSize: 16),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo, brightness: Brightness.dark),
        ),
        themeMode: ThemeMode.system,
        // ✅ auto-switches light/dark based on system
        home: LoginPage(onLoginSuccess: _onLoginSuccess, storage: _storage), // login first
      );
    }
  }
}
