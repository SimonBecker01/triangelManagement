import 'package:flutter/material.dart';
import 'package:management_triangel/global.dart';
import 'package:management_triangel/pages/employees/commondocuments.dart';
import 'package:management_triangel/pages/employees/documents.dart';
import 'package:management_triangel/pages/employer/betreuungen.dart';
import 'package:management_triangel/pages/employer/klienten.dart';
import 'package:management_triangel/pages/login.dart';
import 'package:management_triangel/pages/employees/menu.dart';
import 'package:management_triangel/pages/employees/newdocument.dart';
import 'package:management_triangel/pages/employees/timetracker.dart';
import 'package:management_triangel/pages/employees/changepass.dart';
import 'package:management_triangel/pages/employer/menuE.dart';
import 'package:management_triangel/pages/employer/auswertungen.dart';
import 'package:management_triangel/pages/employer/dokumente.dart';
import 'package:management_triangel/pages/employer/nutzerverwaltung.dart';
import 'package:management_triangel/pages/employer/neuernutzer.dart';
import 'package:management_triangel/pages/employer/rechteverwaltung.dart';
import 'package:management_triangel/pages/employer/rollen.dart';
import 'package:management_triangel/pages/employer/kategorien.dart';
import 'package:management_triangel/pages/employer/gruppen.dart';
import 'package:management_triangel/pages/employer/taetigkeiten.dart';
import 'package:management_triangel/pages/employer/systemeinstellungen.dart';
import 'package:management_triangel/pages/employer/allgdokumente.dart';
import 'package:management_triangel/pages/employer/allgneuesdokument.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    const host = String.fromEnvironment('TRIANGEL_GRPC_HOST', defaultValue: 'allebescheuert.de');
    const port = int.fromEnvironment('TRIANGEL_GRPC_PORT', defaultValue: 50051);
    await globalGrpcClient.connect(host: host, port: port);
  } catch (error) {
    debugPrint('Unable to configure the gRPC client: $error');
  }
  try {
    await initializeDateFormatting("de_DE");
  } catch (error) {
    debugPrint('Date locale initialization failed: $error');
  }
  appTheme.restoreColors();
  runApp(const TriangelManagementMain());
}

class TriangelManagementMain extends StatelessWidget {
  const TriangelManagementMain({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appTheme,
      builder: (context, _) => MaterialApp(
        title: 'Triangel',
        theme: appTheme.light,
        darkTheme: appTheme.dark,
        // Keeps today's behaviour (always light). Change via appTheme.setMode.
        themeMode: appTheme.mode,
        initialRoute: '/login',
        routes: <String, WidgetBuilder>{
          '/login': (BuildContext context) => LoginScreen(),
          '/menu': (BuildContext context) => const MenuScreen(),
          '/timetracker': (BuildContext context) => const TimetrackerScreen(),
          '/documents': (BuildContext context) => const DocumentsScreen(),
          '/newdocument': (BuildContext context) => const NewDocumentScreen(),
          '/changepass': (BuildContext context) => const ChangePassScreen(),
          '/employermenu': (BuildContext context) => const MenuEScreen(),
          '/auswertungen': (BuildContext context) => const AuswertungenScreen(),
          '/dokumente': (BuildContext context) => const DokumenteScreen(),
          '/nutzerverwaltung': (BuildContext context) => const NutzerverwaltungScreen(),
          '/neuernutzer': (BuildContext context) => const NeuerNutzerScreen(),
          '/rechteverwaltung': (BuildContext context) => const RechteverwaltungScreen(),
          '/rollen': (BuildContext context) => const RollenScreen(),
          '/kategorien': (BuildContext context) => const KategorienScreen(),
          '/gruppen': (BuildContext context) => const GruppenScreen(),
          '/taetigkeiten': (BuildContext context) => const TaetigkeitenScreen(),
          '/systemeinstellungen': (BuildContext context) => const SystemeinstellungenScreen(),
          '/allgdokumente': (BuildContext context) => const AllgemeineDokumenteScreen(),
          '/neuesdokument': (BuildContext context) => const AllgemeinesNeuesDokumentScreen(),
          '/betreuungen': (BuildContext context) => const BetreuungenScreen(),
          '/klientenverwaltung': (BuildContext context) => const KlientenverwaltungScreen(),
          '/commondocuments': (BuildContext context) => const CommonDocumentsScreen(),
        },
      ),
    );
  }
}
