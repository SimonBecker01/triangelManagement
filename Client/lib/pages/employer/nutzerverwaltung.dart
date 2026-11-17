import 'package:flutter/material.dart';

import 'user_management_form.dart';

class NutzerverwaltungScreen extends StatelessWidget {
  const NutzerverwaltungScreen({super.key});
  @override
  Widget build(BuildContext context) => const UserManagementForm(create: false);
}
