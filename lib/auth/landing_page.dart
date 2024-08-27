import 'package:flutter/material.dart';
import '../Common/flutter_flow_theme.dart';
import 'login_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the screen size
    final size = MediaQuery.of(context).size;
    final double screenHeight = size.height;
    final double screenWidth = size.width;

    // Access the theme
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromRGBO(0, 0, 0, 0),
              Color.fromRGBO(0, 0, 0, 1),
            ],
          ),
          color: theme.primaryBackground,
          // Uncomment the following lines if the background image is needed.
          // image: DecorationImage(
          //   image: AssetImage('assets/images/Landingpagefinal.png'),
          //   fit: BoxFit.cover, // Use BoxFit.cover to adapt the image to the screen size
          // ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: screenHeight * 0.9, // 90% of the screen height
              left: screenWidth * 0.05, // 5% from the left
              child: InkWell(
                onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );
                      },
                child: Container(
                  width: screenWidth * 0.91, // 91% of the screen width
                  height: screenHeight * 0.07, // 7% of the screen height
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: theme.primary,
                  ),
                  child: Center(
                    child: Text(
                      'Get Started',
                      textAlign: TextAlign.center,
                      style: theme.typography.labelLarge.override(
                        fontFamily: 'Poppins',
                        color: theme.tertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.83, // 83% of the screen height
              left: screenWidth * 0.07, // 7% from the left
              child: SizedBox(
                width: screenWidth * 0.88, // 88% of the screen width
                height: screenHeight * 0.0025, // 0.25% of the screen height
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      left: 0,
                      child: Container(
                        width: screenWidth * 0.28, // 28% of the screen width
                        height: screenHeight * 0.0025, // 0.25% of the screen height
                        color: const Color.fromRGBO(255, 244, 234, 1),
                      ),
                    ),
                    Positioned(
                      left: screenWidth * 0.31, // 31% from the left
                      child: Container(
                        width: screenWidth * 0.28, // 28% of the screen width
                        height: screenHeight * 0.0025, // 0.25% of the screen height
                        color: theme.tertiary,
                      ),
                    ),
                    Positioned(
                      left: screenWidth * 0.61, // 61% from the left
                      child: Container(
                        width: screenWidth * 0.28, // 28% of the screen width
                        height: screenHeight * 0.0025, // 0.25% of the screen height
                        color: theme.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.45, // 45% of the screen height
              left: screenWidth * 0.05, // 5% from the left
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: screenWidth  * 0.95,
                      child: Text(
                        "Let's delve into Varieties of coffee",
                        textAlign: TextAlign.left,
                        style: theme.typography.displaySmall.override(
                          fontSize: 25,
                          color: theme.tertiary,
                          fontFamily: 'Poppins',
                        ),
                        softWrap: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: screenWidth  * 0.95,
                      child: Text(
                        'Join us in exploring a range of coffee flavors with just a few clicks.',
                        textAlign: TextAlign.left,
                        style: theme.typography.bodyLarge.override(
                          color: theme.tertiary,
                          fontFamily: 'Poppins',
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.07, // 7% of the screen height
              left: screenWidth * 0.055, // 5.5% from the left
              child: Container(
                width: screenWidth * 0.78, // 78% of the screen width
                height: screenHeight * 0.125, // 12.5% of the screen height
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/logo_full.png'),
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
