import 'package:flutter/material.dart';
import 'package:management_triangel/services/grpc_client.dart' as grpcp;
import 'package:shared_preferences/shared_preferences.dart';

const Color defaultLightBG = Color.fromRGBO(122, 201, 67, 1);
const Color defaultDarkBG = Color.fromRGBO(88, 140, 52, 1);


class AppTheme extends ChangeNotifier {
  AppTheme({Color light = defaultLightBG, Color dark = defaultDarkBG})
      : _lightBG = light,
        _darkBG = dark;

  Color _lightBG;
  Color _darkBG;
  ThemeMode _mode = ThemeMode.light;

  Color get lightBG => _lightBG;
  Color get darkBG => _darkBG;
  ThemeMode get mode => _mode;

  Color get barColor => _darkBG;

  ThemeData get light => _build(_lightBG, Brightness.light);
  ThemeData get dark => _build(_darkBG, Brightness.dark);

  static ThemeData _build(Color seed, Brightness brightness) => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: brightness,
        ),
      );

  void setLight(Color color) {
    if (color == _lightBG) return;
    _lightBG = color;
    notifyListeners();
  }

  void setDark(Color color) {
    if (color == _darkBG) return;
    _darkBG = color;
    notifyListeners();
  }

  void persistColor ({Color? light, Color? dark}) async {
    final prefs = await SharedPreferences.getInstance();
    if(light != null){
      prefs.setInt("lightR", (light.r * 255).round());
      prefs.setInt("lightG", (light.g * 255).round());
      prefs.setInt("lightB", (light.b * 255).round());
    }
    if(dark != null){
      prefs.setInt("darkR", (dark.r * 255).round());
      prefs.setInt("darkG", (dark.g * 255).round());
      prefs.setInt("darkB", (dark.b * 255).round());
    }
  }

  void setColors({Color? light, Color? dark}) {
    persistColor(light: light, dark: dark);
    var changed = false;
    if (light != null && light != _lightBG) {
      _lightBG = light;
      changed = true;
    }
    if (dark != null && dark != _darkBG) {
      _darkBG = dark;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void setMode(ThemeMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
  }

  void restoreColors() async{
    final prefs = await SharedPreferences.getInstance();
    
    int? lightR = prefs.getInt("lightR");
    int? lightG = prefs.getInt("lightG");
    int? lightB = prefs.getInt("lightB");
    
    int? darkR = prefs.getInt("darkR");
    int? darkG = prefs.getInt("darkG");
    int? darkB = prefs.getInt("darkB");

    if(lightR != null && lightG != null && lightB != null){
      _lightBG = Color.fromRGBO(lightR, lightG, lightB, 1);
    }
    
    if(darkR != null && darkG != null && darkB != null){
      _darkBG = Color.fromRGBO(darkR, darkG, darkB, 1);
    }

  }

  void reset() => setColors(light: defaultLightBG, dark: defaultDarkBG);
}

final AppTheme appTheme = AppTheme();

//Weil es auf Telefonen sonst kaum nutzbar ist...
const double wideLayoutBreakpoint = 600;
bool useWideLayout(BoxConstraints constraints) =>
    constraints.maxWidth >= wideLayoutBreakpoint && constraints.maxHeight >= 450;

double barHeight = 90;

AppBar standardAppBar({List<Widget> actions = const []}) {
  return AppBar(
    title: SizedBox(height: barHeight,child: Image.asset('Assets/Logo.png'),),
    backgroundColor: appTheme.barColor,
    iconTheme: const IconThemeData(color: Colors.black),
    centerTitle: true,
    actions: actions,
    toolbarHeight: barHeight,
  );
}

// CHANGE: both logout and a partially failed login must clear the same state.
void clearSession() {
  globalGrpcClient.setAuthToken('');
  loginName = '';
  currentUserRole = 0;
  passwordResetRequired = false;
  selectedChild = 0;
  selectedActivity = 0;
  selectedDocumentGroup = 0;
  childList.clear();
  childListId.clear();
  activityList.clear();
  activityListId.clear();
  documentGroupList.clear();
  documentGroupListId.clear();
  documentCategoryList.clear();
  documentCategoryListId.clear();
  documentList.clear();
  selectedCategories.clear();
  selectedDocumentGroups.clear();
  activityOnDayList.clear();
}

Widget logoutAction(BuildContext context) {
  return IconButton(
    onPressed: () {
      // Invalidate local credentials and cached data on logout.
      clearSession();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    },
    icon: const Icon(Icons.logout, color: Colors.black54),
    tooltip: 'Abmelden',
  );
}

Widget changePassAction(BuildContext context) {
  return IconButton(
    onPressed: () {
      Navigator.of(context).pushNamed('/changepass');
    },
    icon: const Icon(Icons.password, color: Colors.black54),
    tooltip: 'Passwort ändern',
  );
}

int selectedChild = 0;
int selectedActivity = 0;
int selectedDocumentGroup = 0;

String loginName = '';
int currentUserRole = 0;
bool passwordResetRequired = false;

List<String> childList = <String>[];
List<int> childListId = <int>[];
List<String> activityList = <String>[''];
List<int> activityListId = <int>[];
List<String> documentGroupList = <String>[''];
List<int> documentGroupListId = <int>[];
List<String> documentCategoryList = <String>[''];
List<int> documentCategoryListId = <int>[];
List<(int, String, int, List<int>, String)> documentList =
    <(int, String, int, List<int>, String)>[];

// CHANGE: replaceable in widget tests; production uses the TLS-only singleton.
// Tests restore the singleton after each case.
grpcp.GrpcClient globalGrpcClient = grpcp.GrpcClient.instance;

List<int> selectedCategories = [];
List<int> selectedDocumentGroups = [];

List<(TimeOfDay, TimeOfDay, int, int, String, int)> activityOnDayList =
    <(TimeOfDay, TimeOfDay, int, int, String, int)>[];
