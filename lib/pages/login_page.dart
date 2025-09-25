import 'package:aara_bill_software/db/db_helper.dart';
import 'package:aara_bill_software/pages/dashboard_page.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = "";

  Future<void> _login() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    var user = await DBHelper.getUser(username, password);

    if (user != null) {
      // Navigate to Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } else {
      setState(() {
        _errorMessage = "Invalid credentials!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Login", style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: "Username"),
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _login, child: const Text("Login")),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
