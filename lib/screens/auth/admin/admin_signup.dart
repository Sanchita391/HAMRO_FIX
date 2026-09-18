import 'package:flutter/material.dart';

class AdminSignupPage extends StatelessWidget {
  const AdminSignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB2FFB2),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.admin_panel_settings,
                size: 80,
                color: Color(0xFF0D4D0D),
              ),
              const Text(
                'Admin Portal',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              _field("Admin Username"),
              const SizedBox(height: 15),
              _field("Security PIN", isPass: true),
              const SizedBox(height: 30),
              _loginBtn(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String hint, {bool isPass = false}) => TextField(
    obscureText: isPass,
    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    ),
  );

  Widget _loginBtn() => SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0D4D0D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: const Text(
        "Enter Dashboard",
        style: TextStyle(color: Colors.white),
      ),
    ),
  );
}
