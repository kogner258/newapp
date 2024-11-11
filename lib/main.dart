import 'package:dissonantapp2/screens/payment_screen.dart';
import 'package:dissonantapp2/screens/return_album_screen.dart';
import 'package:dissonantapp2/screens/taste_profile_screen.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'navigator_service.dart';
import 'routes.dart';
import 'screens/feed_screen.dart';
import 'screens/home_screen.dart';
import 'screens/mymusic_screen.dart';
import 'screens/order_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/emailverification_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'models/order_model.dart';
import 'screens/wishlist_screen.dart';
import 'widgets/app_bar_widget.dart';
import 'widgets/bottom_navigation_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart'; // Import the flutter_native_splash package

void main() async {
  // Preserve the splash screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

   FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // You can log the error to an external service here
  };
  
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Set the app to portrait mode only (without awaiting)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // **Initialize Firebase**
  await Firebase.initializeApp();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // **Set the Stripe publishable key**
  Stripe.publishableKey = 'pk_test_...';

  // **Initialize Stripe settings (optional)**
  await Stripe.instance.applySettings();

  // Remove the splash screen after initialization is complete
  FlutterNativeSplash.remove();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OrderModel()),
      ],
      child: MaterialApp(
        title: 'DISSONANT',
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Color(0xFFFFA500), // Orange
          scaffoldBackgroundColor: Colors.black, // Dark Grey
          colorScheme: ColorScheme.dark(
            primary: Color(0xFFFFA500), // Orange
            primaryContainer: Color(0xFFE59400), // Darker Orange
            secondary: Color(0xFFFF4500), // Bright Orange
            secondaryContainer: Color(0xFFCC3700), // Darker Bright Orange
            surface: Colors.black, // Light Grey
            error: Colors.red,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.white,
            onError: Colors.white,
          ),
          textTheme: GoogleFonts.figtreeTextTheme(
            ThemeData.dark().textTheme,
          ).apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
          appBarTheme: AppBarTheme(
            color: Colors.black,
          ),
        ),
        navigatorKey: NavigatorService.navigatorKey,
        routes: {
          welcomeRoute: (context) => WelcomeScreen(),
          homeRoute: (context) => HomeScreen(),
          orderRoute: (context) => OrderScreen(),
          myMusicRoute: (context) => MyMusicScreen(),
          profileRoute: (context) => ProfileScreen(),
          loginRoute: (context) => LoginScreen(),
          registrationRoute: (context) => RegistrationScreen(),
          forgotPasswordRoute: (context) => ForgotPasswordScreen(),
          emailVerificationRoute: (context) => EmailVerificationScreen(),
          tasteProfileRoute: (context) => TasteProfileScreen(),
          wishlistRoute: (context) => WishlistScreen(),
          feedRoute: (context) => FeedScreen(),
        },
        home: AuthenticationWrapper(),
      ),
    );
  }
}


class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          User? user = snapshot.data;
          if (user != null && user.emailVerified) {
            return MyHomePage();
          } else {
            return EmailVerificationScreen();
          }
        } else {
          return WelcomeScreen();
        }
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    OrderScreen(),
    MyMusicScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'DISSONANT'), // Use the custom AppBar
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationWidget(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
