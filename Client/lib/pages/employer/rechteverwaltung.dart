import 'package:flutter/material.dart';
import 'package:management_triangel/global.dart';

class RechteverwaltungScreen extends StatelessWidget {
  const RechteverwaltungScreen({super.key});

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: standardAppBar(actions: [changePassAction(context), logoutAction(context)]),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (useWideLayout(constraints)) {
            return _buildWideLayout(context);
          }
          return _buildNarrowLayout(context);
        },
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            flex: 1,
            child: Row(
              children: [
                Spacer(flex: 9),
              ],
            ),
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                const Spacer(flex: 3),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/rollen');
                    },
                    child: const Text('Rollen'),
                  ),
                ),
                const Spacer(flex: 1),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/kategorien');
                    },
                    child: const Text('Kategorien'),
                  ),
                ),
                const Spacer(flex: 1),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/gruppen');
                    },
                    child: const Text('Gruppen'),
                  ),
                ),
                const Spacer(flex: 1),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/taetigkeiten');
                    },
                    child: const Text('Taetigkeiten'),
                  ),
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
          const Spacer(flex: 4),
        ],
      ),
    );
  }

  // Blöde kleine Bildschirme...
  Widget _buildNarrowLayout(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/rollen');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Rollen'),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/kategorien');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Kategorien'),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/gruppen');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Gruppen'),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/taetigkeiten');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Taetigkeiten'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
