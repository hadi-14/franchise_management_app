import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '.env.dart';
import 'auth/user_setting.dart';
import 'auth/complete_profile.dart';
import 'Common/flutter_flow_theme.dart';
import 'Common/user_state.dart';
import 'HomePage.dart';
import 'auth/landing_page.dart';
import 'order/order_history.dart';
import 'firebase_options.dart';
import 'AppState.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Stripe.publishableKey = stripePublishableKey;
  Stripe.merchantIdentifier = 'merchant.flutter.stripe.test';
  Stripe.urlScheme = 'flutterstripe';
  await Stripe.instance.applySettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserState()),
        ChangeNotifierProvider(create: (_) => AppState()), // Include AppState
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

 SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
 ));

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: FlutterFlowTheme.of(context).primary),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthHandler(),
        '/login': (context) => const LandingPage(),
        '/UserSetting': (context) => UserSetting(),
        '/homePage': (context) => const HomePage(),
        '/order-history': (context) => const OrderHistoryPage(),
        '/franchises': (context) => const OrderHistoryPage(),
      },
    );
  }
}

class AuthHandler extends StatefulWidget {
  const AuthHandler({super.key});

  @override
  _AuthHandlerState createState() => _AuthHandlerState();
}

class _AuthHandlerState extends State<AuthHandler> {
  bool _isLoggedIn = false;
  late User _user;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        setState(() {
          _isLoggedIn = false;
        });
      } else {
        setState(() {
          _isLoggedIn = true;
          _user = user;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) {
      if (_user.photoURL != null) {
        return const HomePage();
      } else {
        return const CompleteProfilePage();
      }
    } else {
      return const LandingPage();
    }
  }
}
