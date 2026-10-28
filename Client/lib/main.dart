import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
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
import 'package:intl/date_symbol_data_local.dart';


Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    try{
      await globalGrpcClient.connect(host: 'allebescheuert.de', port: 50051);
    } on GrpcError catch (e) {
      print('gRPC error: ${e.codeName} (${e.message})');
    }
    await initializeDateFormatting("de_DE");
  runApp(const TriangelManagementMain());
}


class TriangelManagementMain extends StatelessWidget {
  const TriangelManagementMain({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Triangel',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: lightBG),
      ),
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
        '/betreuungen': (BuildContext context) => const BetreuungenScreen(),
        '/klientenverwaltung': (BuildContext context) => const KlientenverwaltungScreen(),
        '/commondocuments': (BuildContext context) => const CommonDocumentsScreen(),
      }
    );
  }
}

