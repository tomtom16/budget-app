import 'package:flutter/material.dart';

class GenericView extends StatelessWidget {

  final String title;

  GenericView(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(title),
      padding: EdgeInsets.all(20),
      child: Center(
        child: Text(
          'Welcome to the $title',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

