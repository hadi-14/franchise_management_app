import 'package:paged_datatable/paged_datatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:franchise_management_app/auth/firebase_login.dart';
import 'package:provider/provider.dart';
import '../HomePage.dart';

import '../Common/flutter_flow_theme.dart';
import '../firebase_options.dart';
import 'Common/CompleteProfile.dart';
import 'Common/user_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print(DefaultFirebaseOptions.currentPlatform);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: FlutterFlowTheme.of(context).primary),
        useMaterial3: true,
      ),
      home: const AuthHandler(),
      localizationsDelegates: const [PagedDataTableLocalization.delegate],
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
    // SharedPreferences prefs = await SharedPreferences.getInstance();

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
        print(user);
      }
    });

    // setState(() {
    //   _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    // });
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
      return const LoginPage();
    }
  }
}
