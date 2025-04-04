import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'loginscreen.dart';

// Responsive design helper
class SizeConfig {
  static MediaQueryData? _mediaQueryData;
  static double? screenW;
  static double? screenH;
  static double? blockH;
  static double? blockV;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenW = _mediaQueryData!.size.width;
    screenH = _mediaQueryData!.size.height;
    blockH = screenW! / 100;
    blockV = screenH! / 100;
  }
}

// Onboarding contents list
class OnboardingContents {
  final String title;
  final String image;
  final String desc;

  OnboardingContents({
    required this.title,
    required this.image,
    required this.desc,
  });
}

List<OnboardingContents> contents = [ // contents in onboarding screen
  OnboardingContents(
    title: "Track Your Sugar Intake",
    image: "lib/images/onboarding1.png",
    desc: "Manually log your meals and track your daily sugar levels.",
  ),
  OnboardingContents(
    title: "Visualize Your Data",
    image: "lib/images/onboarding2.png",
    desc: "See trends over time with detailed charts and insights.",
  ),
  OnboardingContents(
    title: "Make Smarter Choices",
    image: "lib/images/onboarding3.png",
    desc: "Use the OpenFoodFacts API to get nutritional info before consuming.",
  ),
];

class OnboardingScreen extends StatefulWidget {
 final Function(String?) onThemeChanged; 
final VoidCallback onOnboardingComplete; 

  const OnboardingScreen({super.key, required this.onThemeChanged, required this.onOnboardingComplete});

  
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    _controller = PageController();
    super.initState();
  }

  Future<void> _markOnboardingSeen() async { // if user has seen onboarding set it to true
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
  }

  AnimatedContainer _buildDots({int? index}) { // dots (ellipses to show what part of onboarding screen im on)
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: _currentPage == index ? Colors.black : Colors.grey,
      ),
      margin: const EdgeInsets.only(right: 5),
      height: 10,
      width: _currentPage == index ? 20 : 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double width = SizeConfig.screenW!;
    double height = SizeConfig.screenH!;

    return Scaffold(

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: PageView.builder(
                physics: const BouncingScrollPhysics(),
                controller: _controller,
                onPageChanged: (value) => setState(() => _currentPage = value),
                itemCount: contents.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        Image.asset(
                          contents[i].image,
                          height: SizeConfig.blockV! * 35,
                        ),
                        SizedBox(height: (height >= 840) ? 60 : 30),
                        Text(
                          contents[i].title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: (width <= 550) ? 28 : 32,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          contents[i].desc,
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: (width <= 550) ? 16 : 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      contents.length,
                      (int index) => _buildDots(index: index),
                    ),
                  ),
                  _currentPage + 1 == contents.length
                      ? Padding(
                          padding: const EdgeInsets.all(30),
                          child: ElevatedButton(
                            onPressed: () async {
                              await _markOnboardingSeen();
                              widget.onOnboardingComplete(); // Call the callback - THIS IS KEY FOR ONBOARDING (Note to myself : do not change)
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) =>  LoginScreen(onThemeChanged: widget.onThemeChanged)), 
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: width * 0.2, vertical: 20),
                              textStyle: TextStyle(fontSize: (width <= 550) ? 15 : 18),
                            ),
                            child: const Text("GET STARTED"),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  _controller.jumpToPage(contents.length - 1);
                                },
                                style: TextButton.styleFrom(
                                  textStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: (width <= 550) ? 15 : 18,
                                  ),
                                ),
                                child: const Text("SKIP", style: TextStyle()),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  _controller.nextPage(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeIn,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                 
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                                  textStyle: TextStyle(fontSize: (width <= 550) ? 15 : 18),
                                ),
                                child: const Text("NEXT"),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
