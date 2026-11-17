import 'package:flutter/material.dart';

import 'lookup_management.dart';

class KategorienScreen extends StatelessWidget {
  const KategorienScreen({super.key});
  @override
  Widget build(BuildContext context) => const LookupManagementScreen(kind: LookupKind.category);
}
