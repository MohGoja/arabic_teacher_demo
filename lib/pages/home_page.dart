import 'package:flutter/material.dart';
import '../models/lesson_index.dart';
import '../models/lesson.dart';
import 'lesson_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<LessonIndex>? lessons;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadLessonIndex();
  }

  Future<void> _loadLessonIndex() async {
    try {
      final loadedLessons = await loadLessonIndex();
      setState(() {
        lessons = loadedLessons;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _navigateToLesson(String lessonId) async {
    try {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Load the specific lesson
      final lesson = await loadLessonById(lessonId);

      // Dismiss loading indicator and navigate
      if (!mounted) return;
      Navigator.of(context).pop();

      // Navigate to lesson page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LessonPage(lesson: lesson)),
      );
    } catch (e) {
      // Dismiss loading indicator and show error
      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل الدرس: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدروس'), centerTitle: true),
      body: Builder(
        builder: (context) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('خطأ في تحميل الدروس: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isLoading = true;
                        error = null;
                      });
                      _loadLessonIndex();
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          if (lessons == null || lessons!.isEmpty) {
            return const Center(child: Text('لا توجد دروس متاحة'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: lessons!.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final lesson = lessons![index];

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _navigateToLesson(lesson.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson.title,
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${lesson.slideCount} شريحة',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
