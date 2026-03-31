import 'package:budget_app/services/budget_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../dto/login_request.dart';
import '../enums/enums.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final FlutterSecureStorage storage;

  const LoginPage(
      {required this.onLoginSuccess, required this.storage, Key? key})
      : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String _submitButtonText = "Login";

  LoginAction _selectedAction = LoginAction.login;

  Future<void> _handleLogin() async {
    // Replace this with a real REST API call
    //if (_usernameController.text == "admin" && _passwordController.text == "password") {
    if (_usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty) {
      try {
        final LoginRequest data = LoginRequest(
            username: _usernameController.text,
            password: _passwordController.text);

        final response = await BudgetService.login(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login successfully")),
        );
        _formKey.currentState!.reset();
        setState(() {});

        debugPrint(response.token);

        await widget.storage.write(key: 'authToken', value: response.token);
        await widget.storage
            .write(key: 'refreshToken', value: response.refreshToken);

        widget.onLoginSuccess();
      } catch (e, stack) {
        debugPrint(e.toString());
        debugPrintStack(
            stackTrace: stack, label: 'login_request', maxFrames: 10);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid credentials")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid credentials")),
      );
    }
  }

  Future<void> _handleRegister() async {
    if (_usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty) {
      try {
        final LoginRequest data = LoginRequest(
            username: _usernameController.text,
            password: _passwordController.text);

        final response = await BudgetService.register(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Registered successfully, please login")),
        );
        _formKey.currentState!.reset();

        _selectedAction = LoginAction.login;
        _changeButtonText();
        setState(() {});
      } catch (e, stack) {
        debugPrint(e.toString());
        debugPrintStack(
            stackTrace: stack, label: 'register_request', maxFrames: 10);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid credentials")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid credentials")),
      );
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Perform your auth logic here...
      switch (_selectedAction) {
        case LoginAction.login:
          _handleLogin();
        case LoginAction.register:
          _handleRegister();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid credentials")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Login",
                      style: Theme.of(context).textTheme.headlineMedium),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio<LoginAction>(
                        value: LoginAction.login,
                        groupValue: _selectedAction,
                        onChanged: (value) {
                          setState(() {
                            _selectedAction = value!;
                          });
                          _changeButtonText();
                        },
                      ),
                      const Text('Login'),
                      const SizedBox(width: 16),
                      Radio<LoginAction>(
                        value: LoginAction.register,
                        groupValue: _selectedAction,
                        onChanged: (value) {
                          setState(() {
                            _selectedAction = value!;
                          });
                          _changeButtonText();
                        },
                      ),
                      const Text('Register'),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(labelText: "Username"),
                    textInputAction:
                        TextInputAction.next, // moves to next field
                  ),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: "Password"),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(), // press enter to submit
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(_submitButtonText),
                  ),
                ],
              ),
            )),
      ),
    );
  }

  void _changeButtonText() {
    switch (_selectedAction) {
      case LoginAction.login:
        _submitButtonText = "Login";
      case LoginAction.register:
        _submitButtonText = "Register";
    }
  }
}
