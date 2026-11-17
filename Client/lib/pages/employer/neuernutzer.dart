import 'package:flutter/material.dart';

import 'user_management_form.dart';

class NeuerNutzerScreen extends StatelessWidget {
  const NeuerNutzerScreen({super.key});
  @override
  Widget build(BuildContext context) => const UserManagementForm(create: true);
}
