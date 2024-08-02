import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:paged_datatable/paged_datatable.dart';
import 'package:provider/provider.dart';
import 'auth/firebase_login.dart';
import 'auth/edit_credentials.dart';
import 'auth/complete_profile.dart';
import 'Common/flutter_flow_theme.dart';
import 'Common/user_state.dart';
import 'HomePage.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthHandler(),
        '/login': (context) => const LoginPage(),
        '/editCredentials': (context) => const EditCredentialsPage(),
      },
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
      return const LoginPage();
    }
  }
}
