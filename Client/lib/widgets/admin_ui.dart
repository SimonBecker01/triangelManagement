import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:management_triangel/global.dart';

// CHANGE: Shared, bounded, scrollable layout for administrative forms.
// In narrow viewports fields and actions stack instead of placing Expanded
// children inside an unbounded SingleChildScrollView.
class AdminPageLayout extends StatelessWidget {
  const AdminPageLayout({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: standardAppBar(actions: [logoutAction(context)]),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 20),
                ...children,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class AdminGrid extends StatelessWidget {
  const AdminGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth >= 680
          ? (constraints.maxWidth - 16) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [for (final child in children) SizedBox(width: width, child: child)],
      );
    },
  );
}

class AdminActions extends StatelessWidget {
  const AdminActions({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 600) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final child in children) ...[child, const SizedBox(height: 10)],
          ],
        );
      }
      return Wrap(spacing: 12, runSpacing: 10, children: children);
    },
  );
}

InputDecoration adminDecoration(String label) =>
    InputDecoration(labelText: label, border: const OutlineInputBorder(), counterText: '');

// Translate transport failures to actionable messages; never log credentials
// or expose server stack traces to the user.
String requestErrorMessage(Object error) {
  if (error is GrpcError) {
    switch (error.code) {
      case StatusCode.unauthenticated:
        return 'Die Sitzung ist abgelaufen. Bitte erneut anmelden.';
      case StatusCode.permissionDenied:
        return 'Für diesen Vorgang fehlt die Berechtigung.';
      case StatusCode.unavailable:
      case StatusCode.deadlineExceeded:
        return 'Der Server ist nicht erreichbar. Bitte Verbindung prüfen und erneut versuchen.';
      case StatusCode.invalidArgument:
      case StatusCode.failedPrecondition:
      case StatusCode.resourceExhausted:
        return error.message?.isNotEmpty == true ? error.message! : 'Die Eingaben sind ungültig.';
      case StatusCode.notFound:
        return 'Der angeforderte Eintrag wurde nicht gefunden.';
    }
  }
  return 'Der Vorgang ist fehlgeschlagen. Bitte erneut versuchen.';
}

void showRequestError(BuildContext context, Object error) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(requestErrorMessage(error))));
}

Future<bool> confirmRemoval(BuildContext context, String subject) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Löschen bestätigen'),
        content: Text('$subject wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    ) ??
    false;
