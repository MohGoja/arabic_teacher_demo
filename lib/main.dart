import 'package:arabic_teacher_demo/models/theme/custom_colors.dart';
import 'package:arabic_teacher_demo/models/theme/custom_text_style.dart';
import 'package:arabic_teacher_demo/pages/home_page.dart';
import 'package:arabic_teacher_demo/pages/lesson_page.dart';
import 'package:arabic_teacher_demo/models/lesson.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// reached slide 77 in powerpoint with proff
///
///
///
///
///
///
///

//// reached slide 77 in powerpoint and row 226 in google sheets

// ============ DEVELOPMENT CONFIGURATION ============
// Set this to true to load a specific lesson directly for development
const bool kDevelopmentMode = false;
// Specify which lesson to load in development mode
// Available: 'nahw_intro', 'maarifa_nakira', 'muraab_mabni', 'ahkam_al_kalam'
const String kDevelopmentLessonId = 'ahkam_al_kalam';
// ================================================

///TODO make a quiz style the user himself hightlights a letter and decides what that is
///TODO make the graph widget more dynamic and responsive, meaning make it fit the available screen height and width as much as needed
///make the widgets templates accept other widget templates, like the graph each node can accept another template like animation or header or colorfull text
/// same for footnote, it can accept a graph or animation or header or colorfull text
/// TODO make each widget in the lessons slide to show in order first second and third and so on,
/// TODO make a play audio teacher, where the slide widgets will synch with the audio and show with the audio
/// TODO in slide number 16 i don't like the animation too distracting,
/// TODO in ahkam alkalam lesson data, make sure to a3rab each example in examples, not in exercises
///
///
///
///
// ============ DEVELOPMENT INSTRUCTIONS ============
// To quickly load a specific lesson for development:
// 1. Set kDevelopmentMode = true
// 2. Set kDevelopmentLessonId to the lesson you want to load
// 3. Hot reload the app
// Available lesson IDs:
//   - 'nahw_intro'      (مقدمة في علم النحو - 23 slides)
//   - 'maarifa_nakira'  (المعرفة والنكرة - 17 slides)
//   - 'muraab_mabni'    (المـُعْرَبُ والمـَبْنِي - 30 slides)
//   - 'ahkam_al_kalam'  (أحكام الكلام - 53 slides)
// ================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData lightThemeData = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xffd3e8f4), // your hex
        brightness: Brightness.light,
      ),
      primaryColor: const Color(0xFF568da8),
      extensions: [
        const CustomColors(
          lightBg: Color(0xffd3e8f4),
          darkBg: Color(0xff001f2e),
        ),
        CustomTextStyle(
          lessonTitle: GoogleFonts.amiri(
            fontSize: 45,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 61, 96, 116),
            shadows: [
              const Shadow(
                offset: Offset(2, 2), // x, y offset
                blurRadius: 4.0, // how soft the shadow looks
                color: Colors.black26, // shadow color
              ),
            ],
          ),
          lessonText: GoogleFonts.amiri(
            fontSize: 25,
            fontWeight: FontWeight.normal,
            color: const Color.fromARGB(255, 12, 12, 12),
            // shadows: [
            //   const Shadow(
            //     offset: Offset(2, 2), // x, y offset
            //     blurRadius: 4.0, // how soft the shadow looks
            //     color: Colors.black26, // shadow color
            //   ),
            // ],
          ),
        ),
      ],
      useMaterial3: true,
      // appBarTheme: const AppBarTheme(
      //   backgroundColor: Color(0xffd3e8f4), // force your hex color
      //   foregroundColor: Colors.black, // icons/text color
      //   elevation: 0,
      // ),
      textTheme: TextTheme(
        titleMedium: GoogleFonts.scheherazadeNew(
          fontSize: 16.0,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arabic Lessons',
      theme: lightThemeData,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''), // Arabic
      ],
      locale: const Locale('ar', ''), // Force app locale to Arabic
      home:
          kDevelopmentMode
              ? DevelopmentLessonLoader(lessonId: kDevelopmentLessonId)
              : const HomePage(),

      // home: const TesterPage(),
      // home: Scaffold(
      //   appBar: AppBar(title: const Text('الدروس'), centerTitle: true),
      //   body: ListView.separated(
      //     padding: const EdgeInsets.all(16),
      //     itemCount: lessons.length,
      //     separatorBuilder: (_, __) => const SizedBox(height: 12),
      //     itemBuilder: (context, index) {
      //       final lesson = lessons[index];

      //       return Card(
      //         elevation: 2,
      //         shape: RoundedRectangleBorder(
      //           borderRadius: BorderRadius.circular(16),
      //         ),
      //         child: InkWell(
      //           borderRadius: BorderRadius.circular(16),
      //           onTap: () {
      //             Navigator.push(
      //               context,
      //               MaterialPageRoute(
      //                 builder: ((context) {
      //                   return LessonPage(lesson: lesson);
      //                 }),
      //               ),
      //             );
      //           },
      //           child: Padding(
      //             padding: const EdgeInsets.symmetric(
      //               horizontal: 16,
      //               vertical: 18,
      //             ),
      //             child: Row(
      //               textDirection:
      //                   TextDirection
      //                       .rtl, // respects app direction (e.g., Arabic)
      //               children: [
      //                 Expanded(
      //                   child: Text(
      //                     lesson.title,
      //                     textAlign: TextAlign.start,
      //                     style: Theme.of(context).textTheme.titleMedium,
      //                   ),
      //                 ),
      //                 const SizedBox(width: 12),
      //                 const Icon(Icons.chevron_right),
      //               ],
      //             ),
      //           ),
      //         ),
      //       );
      //     },
      //   ),
      // ),
    );
  }
}

/// Development widget to quickly load a specific lesson
class DevelopmentLessonLoader extends StatefulWidget {
  final String lessonId;

  const DevelopmentLessonLoader({super.key, required this.lessonId});

  @override
  State<DevelopmentLessonLoader> createState() =>
      _DevelopmentLessonLoaderState();
}

class _DevelopmentLessonLoaderState extends State<DevelopmentLessonLoader> {
  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    try {
      final lesson = await loadLessonById(widget.lessonId);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LessonPage(lesson: lesson)),
        );
      }
    } catch (e) {
      if (mounted) {
        // If loading fails, fall back to home page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الدرس ${widget.lessonId}: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'الصفحة الرئيسية',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تحميل الدرس: ${widget.lessonId}'),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تحميل الدرس...'),
          ],
        ),
      ),
    );
  }
}


// class HomePage extends StatelessWidget {
//   const HomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: ,
//     );
//   }
// }