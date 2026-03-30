import 'package:budget_app/enums/enums.dart';
import 'package:flutter/material.dart';

class Sidebar extends StatefulWidget {
  final bool isAuthenticated;
  final AppPage selectedPage;
  final ValueChanged<AppPage> onPageSelected;
  final bool isMobile;

  Sidebar({
    required this.isAuthenticated,
    required this.selectedPage,
    required this.onPageSelected,
    required this.isMobile
  });

  @override
  State<Sidebar> createState() => _SidebarState(isMobile);
}

class _SidebarState extends State<Sidebar> {
  bool isCollapsed = false;
  bool isMobile = false;

  _SidebarState(this.isMobile);

  void toggleCollapse() {
    setState(() {
      isCollapsed = !isCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCollapsed ? 70 : 200,
      color: Colors.blueGrey[900],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo or Title
          Padding(
            padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 16),
            child: isCollapsed
                ? Icon(Icons.stacked_bar_chart, color: Colors.white, size: 28)
                : Row(
              children: [
                Icon(Icons.stacked_bar_chart, color: Colors.white, size: 28),
                SizedBox(width: 10),
                Text(
                  'Budget App',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white24),
          // Navigation Buttons
          SidebarButton(
            icon: Icons.dashboard,
            label: 'Dashboard',
            isCollapsed: isCollapsed,
            selected: widget.selectedPage == AppPage.dashboard,
            onTap: () => widget.onPageSelected(AppPage.dashboard),
          ),
          SidebarButton(
            icon: Icons.multiline_chart,
            label: 'Details',
            isCollapsed: isCollapsed,
            selected: widget.selectedPage == AppPage.details,
            onTap: () => widget.onPageSelected(AppPage.details),
          ),
          SidebarButton(
            icon: Icons.bar_chart,
            label: 'Trends',
            isCollapsed: isCollapsed,
            selected: widget.selectedPage == AppPage.trends,
            onTap: () => widget.onPageSelected(AppPage.trends),
          ),
          SidebarButton(
            icon: Icons.list,
            label: 'List Expenses',
            isCollapsed: isCollapsed,
            selected: widget.selectedPage == AppPage.transactions,
            onTap: () => widget.onPageSelected(AppPage.transactions),
          ),
          SidebarButton(
            icon: Icons.add,
            label: 'Add Expense',
            isCollapsed: isCollapsed,
            selected: widget.selectedPage == AppPage.add,
            onTap: () => widget.onPageSelected(AppPage.add),
          ),
          SidebarButton(
            icon: Icons.settings,
            label: 'Settings',
            isCollapsed: isCollapsed,
            selected: widget.selectedPage == AppPage.settings,
            onTap: () => widget.onPageSelected(AppPage.settings),
          ),
          Spacer(),
          _buildHideButton(),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHideButton() {
    if (!isMobile) {
      // Collapse Button
      return IconButton(
        icon: Icon(
          isCollapsed ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
          color: Colors.white70,
          size: 18,
        ),
        onPressed: toggleCollapse,
      );
    } else {
      return SizedBox(height: 16);
    }
  }
}

class SidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isCollapsed;
  final bool selected;
  final VoidCallback onTap;

  SidebarButton({
    required this.icon,
    required this.label,
    required this.isCollapsed,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.blueGrey[700] : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              if (!isCollapsed) ...[
                SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
