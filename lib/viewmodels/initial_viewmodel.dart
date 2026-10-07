import 'package:flutter/material.dart';
import '../views/under_development_view.dart';
// import '../views/login_view.dart';

class InitialViewModel {
  void navigateToLogin(BuildContext context, String userType) {
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Navegando para login como \$userType')));
    // Navigator.push(context, MaterialPageRoute(builder: (context) => LoginView(userType: userType)));
  }

  void navigateToUnderDevelopment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UnderDevelopmentView()),
    );
  }
}
