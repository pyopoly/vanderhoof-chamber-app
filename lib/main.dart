import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'business.dart';
import 'commonFunction.dart';
import 'event.dart';
import 'hike.dart';
import 'recreation.dart';
import 'resource.dart';

/// ThemeData Colors
MaterialColor colorPrimary = createMaterialColor(Color(0xFF01579b));
MaterialColor colorText = createMaterialColor(Color(0xFF666666));
MaterialColor colorAccent = createMaterialColor(Color(0xFFf4a024));
MaterialColor colorBackground = createMaterialColor(Color(0xFFF3F3F3));

/// ThemeData Padding
const EdgeInsets HEADER_INSET = EdgeInsets.fromLTRB(0, 20, 0, 0);
const EdgeInsets CARD_INSET = EdgeInsets.fromLTRB(12, 6, 12, 6);
const EdgeInsets TEXT_INSET = EdgeInsets.fromLTRB(21, 16, 21, 0);
const EdgeInsets ICON_INSET = EdgeInsets.fromLTRB(12, 0, 0, 0);
const EdgeInsets SHOW_MORE_INSET = EdgeInsets.fromLTRB(21, 5, 21, 0);

/// ThemeData Text + Icon Sizes
const double TITLE_SIZE = 22;
const double BODY_SIZE = 16;
const double ICON_SIZE = 30;
const double ICON_SIZE_SMALL = 18;
const int SHOW_MORE_TEXT_COUNT = 150;

/// ThemeData TextStyles
TextStyle titleTextStyle = TextStyle(
    fontSize: TITLE_SIZE, color: colorPrimary, fontWeight: FontWeight.bold);
TextStyle bodyTextStyle = TextStyle(fontSize: BODY_SIZE, color: colorText);
TextStyle headerTextStyle = TextStyle(
    fontSize: BODY_SIZE, color: colorText, fontWeight: FontWeight.bold);
TextStyle header2TextStyle = TextStyle(
    fontSize: BODY_SIZE - 2, color: colorText, fontWeight: FontWeight.bold);

/// ThemeData Divider
Divider cardDivider = Divider(height: 5, thickness: 4, color: colorAccent);

/// ThemeData Shadows for icon
BoxShadow iconShadow = BoxShadow(
    color: Colors.grey.withOpacity(0.5),
    blurRadius: 3,
    spreadRadius: 3,
    offset: Offset(0, 4));

/// root function to run and initialize app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

/// root class that has the root application
class MyApp extends StatelessWidget {
  // Create the initialization Future outside of `build`:
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _initialization,
        builder: (context, AsyncSnapshot snapshot) {
          // Show splash screen while waiting for app resources to load:
          if (snapshot.connectionState == ConnectionState.waiting) {
            return MaterialApp(home: Splash());
          } else if (snapshot.hasError) {
            // Check for errors
            return Text("Something went wrong: ${snapshot.error}",
                textDirection: TextDirection.ltr);
          }
          // Once complete, show your application
          else {
            // Loading is done, return the app:
            return MaterialApp(
                title: "Vanderhoof Chamber Admin App",
                theme: ThemeData(
                  primarySwatch: colorPrimary,
                  primaryColor: colorPrimary,
                  accentColor: colorAccent,
                ),
                home: MyHomePage(title: 'Landing Page'));
          }
        });
  }
}

/// Landing Page
class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

/// Landing Page State
class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool isLandingPage = true;
  AnimationController _controller;
  Animation<Offset> _animation;
  Image backgroundImage;

  // different background images
  final List<String> _imagePaths = [
    'assets/images/background_Denys_Poirier.jpg',
    'assets/images/background_Liam_Dauphinais.jpg',
    'assets/images/background_Nicole_Dawn_Michels.jpg',
    'assets/images/background_Tammy_Zacharias.jpg',
    'assets/images/background_Tanya_Morris.jpg',
  ];

  // list of other pages to navigate to
  final List<Widget> _children = [
    BusinessState(),
    ResourceState(),
    EventState(),
    Hike(),
    Recreation(),
  ];

  /// navigate to selected page at _children [index]
  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// init class and insert object to tree
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    Timer(Duration(milliseconds: 200), () => _controller.forward());

    _animation = Tween<Offset>(
      begin: Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutBack,
    ));

    backgroundImage = getRandomBackgroundImage();
  }

  /// preload background image
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(backgroundImage.image, context);
  }

  /// get random background image from [assets/images/background_***]
  Image getRandomBackgroundImage() {
    Random random = new Random();
    int randomNumber = random.nextInt(5);
    String imagePath = _imagePaths[randomNumber];
    return Image.asset(imagePath);
  }

  /// build for an action with a slide-in animation
  /// button slides in from the right to it's original position
  /// also has a slight face in
  Widget buildAnimatedSlideInAction(Widget childWidget) {
    return Builder(
      builder: (context) => Center(
        child: SlideTransition(
          position: _animation,
          transformHitTests: true,
          textDirection: TextDirection.ltr,
          child: FadeTransition(opacity: _controller, child: childWidget),
        ),
      ),
    );
  }

  /// build for a GoToPage button, will navigate to pageIndex when selected
  Widget buildGoToPageButton(Widget pageIcon, String pageName, int pageIndex) {
    return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Align(
          alignment: Alignment.center,
          child: ElevatedButton.icon(
              style: TextButton.styleFrom(
                  backgroundColor: colorPrimary,
                  primary: colorAccent,
                  minimumSize: Size(230, 45),
                  elevation: 3,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  )),
              icon: pageIcon,
              label: Text('$pageName',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  )),
              onPressed: () {
                setState(() {
                  isLandingPage = false;
                  _selectedIndex = pageIndex;
                });
              }),
        ));
  }

  /// build for a Landing Page, select a page to navigate out of it
  Widget buildLandingPage() {
    return Container(
      // comment out 'decoration' argument to hide background image
      decoration: BoxDecoration(
          image: DecorationImage(
        image: backgroundImage.image,
        fit: BoxFit.cover,
      )),
      width: double.infinity,
      height: double.infinity,
      child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
              padding: const EdgeInsets.only(top: 150),
              child: buildAnimatedSlideInAction(
                Column(
                  children: [
                    Container(
                      decoration:
                          BoxDecoration(color: Colors.white.withOpacity(0.8)),
                      child: Image(
                          image: AssetImage(
                              'assets/images/vanderhoof_chamber_logo_large.png')),
                    ),
                    buildGoToPageButton(Icon(MdiIcons.briefcaseVariant),
                        'Business Directory', 0),
                    buildGoToPageButton(FaIcon(FontAwesomeIcons.infoCircle),
                        'Business Resources', 1),
                    buildGoToPageButton(Icon(Icons.event), 'Events', 2),
                    buildGoToPageButton(
                        Icon(MdiIcons.hiking), 'Hiking Trails', 3),
                    buildGoToPageButton(
                        Icon(Icons.directions_bike), 'Recreational', 4),
                  ],
                ),
              ))),
    );
  }

  /// Final Build Widget
  /// =========================
  /// this widget contains the body of the other pages,
  /// and a persistent bottom navigation bar to navigate to the other pages
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: isLandingPage ? buildLandingPage() : _children[_selectedIndex],
      bottomNavigationBar: isLandingPage
          ? Container(width: 0, height: 0)
          : BottomNavigationBar(
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(MdiIcons.briefcaseVariant),
                  label: 'Businesses',
                  backgroundColor: colorPrimary,
                ),
                BottomNavigationBarItem(
                  icon: FaIcon(FontAwesomeIcons.infoCircle),
                  label: 'Resources',
                  backgroundColor: colorPrimary,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.event),
                  label: 'Events',
                  backgroundColor: colorPrimary,
                ),
                BottomNavigationBarItem(
                  icon: Icon(MdiIcons.hiking), // hiking
                  label: 'Hiking',
                  backgroundColor: colorPrimary,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.directions_bike),
                  label: 'Recreational',
                  backgroundColor: colorPrimary,
                )
              ],
              currentIndex: _selectedIndex,
              onTap: _onTabTapped,
              selectedItemColor: colorAccent,
              unselectedItemColor: Colors.white,
            ),
    );
  }
}

/// The Secondary Splash screen that appears after the app has loaded. This is
/// the screen that shows up when firebase is being initialized.
class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Image.asset("assets/images/vanderhoof_chamber_logo_only.png")
          // Icon(
          //   Icons.apartment_outlined,
          //   size: MediaQuery.of(context).size.width * 0.785,
          // ),
          ),
    );
  }
}
