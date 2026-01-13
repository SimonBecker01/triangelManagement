import 'package:flutter/material.dart';

void main() {
  runApp(const TriangelManagementMain());
}

class TriangelManagementMain extends StatelessWidget {
  const TriangelManagementMain({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Triangel',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: const Color.fromRGBO(122, 201, 67, 1)),
      ),
      home: const MainPage(title: 'Demonstration Management System'),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MainPage> createState() => _LoginState();
}

class _LoginState extends State<MainPage> {

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff407ff1),
        title: Text(widget.title),
      ),
body: Container(
height: (MediaQuery.of(context).size.height - AppBar().preferredSize.height),
width: MediaQuery.of(context).size.width,
child: SingleChildScrollView(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [

Container(
height: 200,
width: MediaQuery.of(context).size.width,
decoration: BoxDecoration(
color: const Color(0xff407ff1),
border: Border.all(color: const Color(0x00000000)),
borderRadius: const BorderRadius.only(
topLeft: Radius.circular(0),
topRight: Radius.circular(0),
bottomLeft: Radius.circular(0),
bottomRight: Radius.circular(0),
)
),
alignment: Alignment.center,
child: SizedBox(
height: MediaQuery.of(context).size.height,
width: MediaQuery.of(context).size.width,
child: GridView(
gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
scrollDirection: Axis.horizontal,
children: [

Padding(
padding: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 10),
child: Padding(
padding: const EdgeInsets.only(top: 0, left: 200, right: 200, bottom: 0),
child: IconButton(
onPressed: (){
print("button click...");
},
color: const Color(0xff000000),
icon: Icon(Icons.arrow_back,color: Color(0xff000000),size: 20),
),
),
),

Padding(
padding: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 10),
child: MaterialButton(
onPressed: (){
print("button click...");
},
height: MediaQuery.of(context).size.height,
minWidth: MediaQuery.of(context).size.width,
elevation: null,
color: const Color(0xff394965),
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.only(
topLeft: Radius.circular(6),
topRight: Radius.circular(6),
bottomLeft: Radius.circular(6),
bottomRight: Radius.circular(6),
)
),
child: Text("Continue",
 style: const TextStyle(
color: Color(0xffffffff),
fontWeight: FontWeight.w400,
fontSize: 14,
),),
),
),

Padding(
padding: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 10),
child: MaterialButton(
onPressed: (){
print("button click...");
},
height: MediaQuery.of(context).size.height,
minWidth: MediaQuery.of(context).size.width,
elevation: null,
color: const Color(0xff407ff1),
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.only(
topLeft: Radius.circular(6),
topRight: Radius.circular(6),
bottomLeft: Radius.circular(6),
bottomRight: Radius.circular(6),
)
),
child: Text("Continue",
 style: const TextStyle(
color: Color(0xffffffff),
fontWeight: FontWeight.w400,
fontSize: 14,
),),
),
),

Padding(
padding: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 10),
child: MaterialButton(
onPressed: (){
print("button click...");
},
height: null,
minWidth: null,
elevation: null,
color: const Color(0xff407ff1),
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.only(
topLeft: Radius.circular(6),
topRight: Radius.circular(6),
bottomLeft: Radius.circular(6),
bottomRight: Radius.circular(6),
)
),
child: Text("Continue",
 style: const TextStyle(
color: Color(0xffffffff),
fontWeight: FontWeight.w400,
fontSize: 14,
),),
),
),
],
),
),
),

])),
),);
  }
}

class _LoginPageState extends State<MainPage> {

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: GridView.count(
        primary: false,
        crossAxisCount: 3,
        children:  <Widget>[
          Spacer(),
          Container(
            child: const Text('You have pushed the button this many times:'),
          ),
          DatePickerDialog(firstDate: DateTime(2025, 01, 01), lastDate: DateTime(2025, 12, 31))
        ],
      ),
    );
  }
}
