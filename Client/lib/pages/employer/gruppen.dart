import 'package:flutter/material.dart';

import 'lookup_management.dart';

class GruppenScreen extends StatelessWidget {
  const GruppenScreen({super.key});
  @override
  Widget build(BuildContext context) => const LookupManagementScreen(kind: LookupKind.group);
}
