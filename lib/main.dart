import 'package:budget_app/auth/auth_state.dart';
import 'package:budget_app/context/variable_holder.dart';
import 'package:budget_app/views/login.dart';
import 'package:flutter/material.dart';

import 'auth/token_storage.dart';
import 'auth/token_storage_factory.dart';
import 'enums/enums.dart';
import 'views/add_entry_view.dart';
import 'views/dashboard.dart';
import 'views/detail_dashboard.dart';
import 'views/generic_view.dart';
import 'views/transactions.dart';
import 'views/trends.dart';
import 'widgets/sidebar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = createTokenStorage();
  final authState = AuthState(storage);

  await authState.init(); // 🔥 important

  runApp(MyApp(authState, storage));
}

class MyApp extends StatelessWidget {
  final AuthState authState;
  final TokenStorage storage;

  const MyApp(this.authState, this.storage);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: authState,
      builder: (context, _) {
        return MaterialApp(
          title: 'Budget App',
          theme: ThemeData.light(),
          home: MainScreen(authState),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  AuthState authState;

  MainScreen(this.authState);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  AppPage _selectedPage = AppPage.dashboard;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TokenStorage _storage = VariableHolder.getStorage();

  void _onLoginSuccess() async {
    String? token = await _storage.getAccessToken();
    setState(() {
      if (token != null) widget.authState.login(token);
    });
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

  Future<void> removeAuth() async {
    widget.authState.logout();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.authState.isAuthorized) {
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
                      isAuthenticated: widget.authState.isAuthorized,
                      selectedPage: _selectedPage,
                      onPageSelected: (page) {
                        setState(() => _selectedPage = page);
                        Navigator.of(context).pop(); // close drawer
                      },
                      onLogout: (status) {
                        removeAuth();

                        setState(() {});
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
                      isAuthenticated: widget.authState.isAuthorized,
                      selectedPage: _selectedPage,
                      onPageSelected: (page) {
                        setState(() => _selectedPage = page);
                      },
                      onLogout: (status) {
                        removeAuth();
                        setState(() {});
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
        title: "Budget App",
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
        home: LoginPage(
            onLoginSuccess: _onLoginSuccess, storage: _storage), // login first
      );
    }
  }
}
