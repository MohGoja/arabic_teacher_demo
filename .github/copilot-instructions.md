# Arabic Teacher Demo - AI Coding Instructions

## Project Overview

This is a Flutter application for teaching Arabic grammar (النحو) with interactive content blocks, animations, quizzes, and audio narration. The app presents lessons as slides containing various content types with sophisticated text animations and visual elements.

## Architecture & Data Flow

### Core Content Model (JSON → Dart)
- **Lessons** contain multiple **Slides**, each with a title and array of **ContentBlocks**
- Content is dynamically loaded: lesson index from `assets/lesson_index.json`, individual lessons from `assets/lessons/{lesson_id}.json`
- The JSON structure is strictly typed through models: `Lesson` → `Slide` → `ContentBlock`
- Individual lessons are loaded on-demand via `loadLessonById()` for better performance and memory usage

### Block-Based Content System
All lesson content is rendered through the **BlockWidget** (`lib/widgets/block_widget.dart`) which maps `BlockType` enum to specific widgets:

```dart
// 13 supported block types with specific rendering patterns
case BlockType.text: return AnimatedBlockText(...);
case BlockType.colorText: return ColorTextWidget(...);
case BlockType.quiz: return QuizBlockWidget(...);
case BlockType.matchingQuiz: return MatchingQuizWidget(...);
case BlockType.graph: return AnimatedTreeGraph(...);
case BlockType.bulletPoints: return BulletPointsWidget(...);
// etc.
```

### Key Widget Patterns

#### 1. **AnimatedText System** (`lib/widgets/animated_text.dart`)
- 5 animation modes: `none`, `typewriter`, `scramble`, `slide`, `boom`
- Handles both String and List data types for segmented content
- RTL text direction support with Arabic character handling
- Global animation mode controlled via lesson page settings

#### 2. **Custom Theme Extensions**
```dart
// Access custom colors/text styles via theme extensions
Theme.of(context).extension<CustomColors>()!.lightBg
Theme.of(context).extension<CustomTextStyle>()!.lessonText
```

#### 3. **Arabic-First Design**
- `TextDirection.rtl` for Arabic text layout
- Google Fonts (Amiri, Scheherazade New) for Arabic typography
- Audio narration with playback speed controls and narrator selection

## Development Workflows

### Development Mode Configuration
- Use **development flags** in `lib/main.dart`: `kDevelopmentMode = true` and `kDevelopmentLessonId = 'lesson_id'`
- Available lesson IDs: `'nahw_intro'`, `'maarifa_nakira'`, `'muraab_mabni'`, `'ahkam_al_kalam'`
- Development mode bypasses home page and loads specific lesson directly for faster iteration

### Adding New Block Types
1. Add enum to `BlockType` in `lib/models/content_block.dart`
2. Update `ContentBlock.fromJson()` factory for data parsing
3. Add case to switch statement in `BlockWidget.build()`
4. Create corresponding widget in `lib/widgets/`

### Content Creation
- Reference `assets/block_types_and_slide_structure_guide.txt` for JSON schema
- Use `lesson_templates.txt` for common patterns
- Test with `lib/pages/tester_page.dart` for widget development

### Lesson Management
- Individual lessons stored in `assets/lessons/{lesson_id}.json`
- Lesson metadata in `assets/lesson_index.json` for home screen display
- Use `loadLessonById()` for dynamic loading, `loadLessonIndex()` for lesson list

### Audio Integration
- Audio files hosted externally: `https://bnmalek.com/wp-content/uploads/language-app/lessons-audio/lesson-1/{narrator}/{slide}.mp3`
- Narrator selection: `khalid`, `mark`, `anas`, `hamid`, `mazen`, `moncellence`
- Playback rate control (0.9x - 1.5x) with live adjustment during playback

## Critical Conventions

### Widget State Management
- **AnimationControllers**: Always use `with TickerProviderStateMixin` and dispose properly
- **Quiz Widgets**: Maintain answer state and visual feedback (pulse animations for wrong answers)
- **Audio Player**: Single global instance with state synchronization

### Data Type Handling
```dart
// BlockWidget handles polymorphic data gracefully
dynamic parsedData;
if (type == BlockType.graph) {
  parsedData = GraphContent.fromJson(json['data']);
} else if (type == BlockType.selectiveText) {
  parsedData = SelectiveTextData.fromMap(json['data']);
}
```

### Arabic Text Processing
- Use `Characters` package for proper Arabic character iteration
- Handle diacritics separately in `ColorTextWidget` for grammatical highlighting
- Always specify `textDirection: TextDirection.rtl` for Arabic content

## File Organization

```
lib/
├── models/          # Data models and JSON parsing
├── pages/           # Full-screen pages (LessonPage, TesterPage)  
├── widgets/         # Reusable UI components (BlockWidget, etc.)
└── main.dart        # App setup, theme, localization

assets/
├── lesson_index.json              # Lesson metadata for home screen
├── lesson_sample.json             # Legacy file (kept for reference)
├── lessons/                       # Individual lesson files by ID
│   ├── nahw_intro.json
│   ├── maarifa_nakira.json
│   ├── muraab_mabni.json
│   └── ahkam_al_kalam.json
├── block_types_and_slide_structure_guide.txt  # Content schema reference
└── animations/      # Rive animation files
```

## Integration Points

### External Dependencies
- **audioplayers**: Remote MP3 streaming with speed control
- **rive**: Interactive animations (`assets/animations/*.riv`)
- **google_fonts**: Arabic typography (Amiri, Scheherazade New)

### Content-Widget Mapping
- JSON `type` field directly maps to `BlockType` enum values
- Each block type has a dedicated widget class following `*BlockWidget` naming
- Complex data types (graphs, quizzes) use custom model classes for type safety

## Common Pitfalls

1. **Animation Disposal**: Always dispose AnimationControllers to prevent memory leaks
2. **Arabic Typography**: Don't use generic fonts - Arabic requires specific font families
3. **Audio State**: Check `_isPlaying` before allowing new audio playback
4. **JSON Parsing**: Handle both List and Map data types in ContentBlock factory
5. **RTL Layout**: Always specify RTL direction for Arabic text widgets

## Testing & Debugging

- Use `TesterPage` for isolated widget testing
- Audio debugging: Check network connectivity and URL formation
- Animation performance: Monitor frame rate with large text content
- JSON validation: Verify against block type guide before adding new content