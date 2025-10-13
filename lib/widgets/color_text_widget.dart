// lib/widgets/color_text.dart
import 'package:flutter/material.dart';

/// ---------------- DATA MODEL ----------------
// A) Color only the letter س in each “يسجد” (2nd base letter, index = 1)
// {
//   "type": "colorText",
//   "data": {
//     "full_text": "يسجدُ محمدٌ لله. لن يسجدَ محمد لغير الله. لم يسجدْ محمد إلا لله",
//     "textStyle": { "fontSize": 22, "fontWeight": "w600" },
//     "highlights": [
//       { "literal": "يسجد", "occurrence": 1, "charIndex": 1,
//         "baseStyle": { "color": "#F59E0B" } },

//       { "literal": "يسجد", "occurrence": 2, "charIndex": 1,
//         "baseStyle": { "color": "#F59E0B" } },

//       { "literal": "يسجد", "occurrence": 3, "charIndex": 1,
//         "baseStyle": { "color": "#F59E0B" } }
//     ]
//   }
// }

// B) Color only the sukūn on the letter د (last base letter, index = 3) in the 3rd “يسجد”
// {
//   "type": "colorText",
//   "data": {
//     "full_text": "يسجدُ محمدٌ لله. لن يسجدَ محمد لغير الله. لم يسجدْ محمد إلا لله",
//     "highlights": [
//       { "literal": "يسجد", "occurrence": 3, "charIndex": 3,
//         "applyBase": false, "applyDiacritics": true,
//         "diacritics": ["ْ"], "diacriticStyle": { "color": "#7C3AED" } }
//     ]
//   }
// }

// C) Color a range of letters within the word (e.g., 2nd..3rd letters)
// {
//   "type": "colorText",
//   "data": {
//     "full_text": "يسجدُ محمدٌ لله...",
//     "highlights": [
//       { "literal": "يسجد", "occurrence": 1,
//         "charStart": 1, "charEnd": 3,
//         "baseStyle": { "color": "#10B981" } }
//     ]
//   }
// }

class ColorTextData {
  final String fullText;
  final TextStyle? textStyle; // global/default style
  final List<HighlightSpec> highlights;

  ColorTextData({
    required this.fullText,
    required this.highlights,
    this.textStyle,
  });

  factory ColorTextData.fromMap(Map<String, dynamic> data) {
    final full = data['full_text']?.toString() ?? '';
    final tsRaw =
        (data['textStyle'] ?? data['text_style']) as Map<String, dynamic>?;
    final textStyle = tsRaw != null ? _parseTextStyle(tsRaw) : null;

    final List specsRaw = (data['highlights'] as List?) ?? const [];
    final specs =
        specsRaw
            .map(
              (e) => HighlightSpec.fromMap(Map<String, dynamic>.from(e as Map)),
            )
            .toList();

    return ColorTextData(
      fullText: full,
      highlights: specs,
      textStyle: textStyle,
    );
  }
}

class HighlightSpec {
  final String? literal; // target exact substring
  final String? regex; // OR regex
  final int? start; // OR explicit range [start,end)
  final int? end;

  // Which base letters (inside the matched word) to affect.
  // Indexing is 0-based over **base letters only** (diacritics are skipped).
  final int? charIndex; // e.g. 1 = the second base letter in the match
  final List<int>? charIndices; // e.g. [0, 2]
  final int? charStart; // half-open range start within base letters
  final int? charEnd; // half-open range end   within base letters

  /// which occurrences (1-based). If omitted => all matches of literal/regex/range.
  final int? occurrence;
  final List<int>? occurrences;

  /// What to color for that matched occurrence
  final bool applyBase; // color base letters?
  final bool applyDiacritics; // color attached diacritics?
  final List<String>? diacritics; // restrict to these marks, null = any

  /// Styles (preferred) — you can still use legacy baseColor/diacriticColor if you want
  final TextStyle? baseStyle;
  final TextStyle? diacriticStyle;

  /// Legacy shorthand (optional) — merged into the styles above (style wins unless color provided)
  final Color? baseColor;
  final Color? diacriticColor;

  const HighlightSpec({
    this.charIndex,
    this.charIndices,
    this.charStart,
    this.charEnd,
    this.literal,
    this.regex,
    this.start,
    this.end,
    this.occurrence,
    this.occurrences,
    this.applyBase = true,
    this.applyDiacritics = true,
    this.diacritics,
    this.baseStyle,
    this.diacriticStyle,
    this.baseColor,
    this.diacriticColor,
  });

  factory HighlightSpec.fromMap(Map<String, dynamic> m) {
    // legacy diacriticOnly => apply only diacritics
    final diacriticOnly = (m['diacriticOnly'] == true);
    int? _int(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');
    List<int>? _ints(dynamic v) {
      if (v is! List) return null;
      final out = <int>[];
      for (final x in v) {
        final n = _int(x);
        if (n != null) out.add(n);
      }
      return out.isEmpty ? null : out;
    }

    return HighlightSpec(
      charIndex: _int(m['charIndex']),
      charIndices: _ints(m['charIndices']),
      charStart: _int(m['charStart']),
      charEnd: _int(m['charEnd']),
      literal: m['literal']?.toString(),
      regex: m['regex']?.toString(),
      start: m['start'] is int ? m['start'] : int.tryParse('${m['start']}'),
      end: m['end'] is int ? m['end'] : int.tryParse('${m['end']}'),
      occurrence:
          m['occurrence'] is int
              ? m['occurrence']
              : int.tryParse('${m['occurrence']}'),
      occurrences: _parseIntList(m['occurrences']),
      applyBase:
          diacriticOnly
              ? false
              : (m['applyBase'] is bool ? m['applyBase'] : true),
      applyDiacritics:
          m['applyDiacritics'] is bool ? m['applyDiacritics'] : true,
      diacritics: _parseStringList(m['diacritics']),
      baseStyle: _parseTextStyle(m['baseStyle']),
      diacriticStyle: _parseTextStyle(m['diacriticStyle']),
      baseColor: _parseColor(m['baseColor']),
      diacriticColor: _parseColor(m['diacriticColor']),
    );
  }
}

/// ---------------- WIDGET ----------------
class ColorTextWidget extends StatelessWidget {
  final ColorTextData model;
  final TextStyle? textStyle; // runtime override (wins over model.textStyle)
  final TextDirection textDirection;

  const ColorTextWidget({
    super.key,
    required this.model,
    this.textStyle,
    this.textDirection = TextDirection.rtl,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = (textStyle ??
            model.textStyle ??
            DefaultTextStyle.of(context).style)
        .copyWith(height: (textStyle ?? model.textStyle)?.height ?? 1.4);

    final text = model.fullText;
    if (text.isEmpty || model.highlights.isEmpty) {
      return Directionality(
        textDirection: textDirection,
        child: Text(text, style: defaultStyle),
      );
    }

    final n = text.length;
    final List<TextStyle?> baseAt = List<TextStyle?>.filled(n, null);
    final List<TextStyle?> diaAt = List<TextStyle?>.filled(n, null);
    final List<TextStyle?> attachDiaFromBase = List<TextStyle?>.filled(
      n,
      null,
    ); // inherit to following marks

    // Apply each spec (later specs override earlier ones)
    for (final spec in model.highlights) {
      final matches = <_Range>[];

      if (spec.literal != null && spec.literal!.isNotEmpty) {
        var idx = 0;
        final needle = spec.literal!;
        while (true) {
          idx = text.indexOf(needle, idx);
          if (idx < 0) break;
          matches.add(_Range(idx, idx + needle.length));
          idx += 1; // allow overlaps
        }
      } else if (spec.regex != null && spec.regex!.isNotEmpty) {
        final re = RegExp(spec.regex!, unicode: true);
        for (final m in re.allMatches(text)) {
          matches.add(_Range(m.start, m.end));
        }
      } else if (spec.start != null && spec.end != null) {
        final s = spec.start!.clamp(0, n);
        final e = spec.end!.clamp(0, n);
        if (e > s) matches.add(_Range(s, e));
      }

      Iterable<_Range> chosen = matches;
      if (spec.occurrence != null ||
          (spec.occurrences != null && spec.occurrences!.isNotEmpty)) {
        final want = <int>{};
        if (spec.occurrence != null) want.add(spec.occurrence!);
        if (spec.occurrences != null) want.addAll(spec.occurrences!);
        int k = 1;
        chosen = matches.where((_) => want.contains(k++)).toList();
      }

      // Compose per-spec overrides
      final TextStyle? baseOverride = _composeStyle(
        spec.baseStyle,
        spec.baseColor,
      );
      final TextStyle? diaOverride = _composeStyle(
        spec.diacriticStyle,
        spec.diacriticColor,
      );

      Set<int>? _wantedSet(HighlightSpec spec) {
        if (spec.charIndex != null) return {spec.charIndex!};
        if (spec.charIndices != null && spec.charIndices!.isNotEmpty)
          return {...spec.charIndices!};
        if (spec.charStart != null &&
            spec.charEnd != null &&
            spec.charEnd! > spec.charStart!) {
          return {for (int i = spec.charStart!; i < spec.charEnd!; i++) i};
        }
        return null; // null = all base letters in the matched word
      }

      for (final r in chosen) {
        _applyOccurrence(
          text: text,
          start: r.start,
          end: r.end,
          applyBase: spec.applyBase,
          applyDiacritics: spec.applyDiacritics,
          allowedMarks: spec.diacritics,
          baseOverride: baseOverride,
          diaOverride: diaOverride,
          baseAt: baseAt,
          diaAt: diaAt,
          attachDiaFromBase: attachDiaFromBase,
          wanted: _wantedSet(spec),
        );
      }
    }

    // Build spans by grouping consecutive indices with same final style
    final spans = <InlineSpan>[];
    if (n == 0) {
      return Directionality(
        textDirection: textDirection,
        child: RichText(text: TextSpan(style: defaultStyle, children: spans)),
      );
    }

    String _styleKey(TextStyle s) {
      final c = s.color?.value.toRadixString(16) ?? '';
      final bg = s.backgroundColor?.value.toRadixString(16) ?? '';
      final d = s.decoration;
      final dc = s.decorationColor?.value.toRadixString(16) ?? '';
      final fs = s.fontSize?.toStringAsFixed(2) ?? '';
      final fw = s.fontWeight?.index.toString() ?? '';
      final fsty = s.fontStyle == FontStyle.italic ? 'i' : 'n';
      final ls = s.letterSpacing?.toStringAsFixed(2) ?? '';
      final h = s.height?.toStringAsFixed(2) ?? '';
      final fam = s.fontFamily ?? '';
      return '$c|$bg|$d|$dc|$fs|$fw|$fsty|$ls|$h|$fam';
    }

    TextStyle? _inheritDia;

    TextStyle eff(int i) {
      final cu = text.codeUnitAt(i);
      final isDia = _isArabicDiacritic(cu);
      final style =
          isDia
              ? (diaAt[i] ??
                  _inheritDia) // resolved at loop time by _inheritDia
              : baseAt[i];
      return (style == null) ? defaultStyle : defaultStyle.merge(style);
    }

    int runStart = 0;
    TextStyle? current;
    String? currentKey;

    for (int i = 0; i < n; i++) {
      final cu = text.codeUnitAt(i);
      final isDia = _isArabicDiacritic(cu);
      if (!isDia) {
        // update inheritance for the marks that follow this base letter
        _inheritDia = attachDiaFromBase[i];
      }
      final s = eff(i);
      final k = _styleKey(s);

      if (i == 0) {
        current = s;
        currentKey = k;
      } else if (k != currentKey) {
        // flush previous
        spans.add(TextSpan(text: text.substring(runStart, i), style: current));
        runStart = i;
        current = s;
        currentKey = k;
      }
    }
    // flush tail
    spans.add(TextSpan(text: text.substring(runStart), style: current));

    return Directionality(
      textDirection: textDirection,
      child: RichText(
        text: TextSpan(style: defaultStyle, children: spans),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _applyOccurrence({
    required String text,
    required int start,
    required int end,
    required bool applyBase,
    required bool applyDiacritics,
    required List<String>? allowedMarks,
    required TextStyle? baseOverride,
    required TextStyle? diaOverride,
    required List<TextStyle?> baseAt,
    required List<TextStyle?> diaAt,
    required List<TextStyle?> attachDiaFromBase,
    required Set<int>? wanted, // <-- NEW
  }) {
    final n = text.length;

    int baseIdxInMatch = -1; // counts base letters only (diacritics skipped)
    for (int i = start; i < end && i < n; i++) {
      final cu = text.codeUnitAt(i);
      final isDia = _isArabicDiacritic(cu);

      if (!isDia) {
        baseIdxInMatch++;
        final selected = (wanted == null) || wanted.contains(baseIdxInMatch);

        if (selected) {
          if (applyBase && baseOverride != null) baseAt[i] = baseOverride;

          if (applyDiacritics && diaOverride != null) {
            // diacritics attached to this selected base
            attachDiaFromBase[i] = diaOverride;

            int j = i + 1;
            while (j < n && _isArabicDiacritic(text.codeUnitAt(j))) {
              final mark = text[j];
              if (allowedMarks == null || allowedMarks.contains(mark)) {
                diaAt[j] = diaOverride;
              }
              j++;
            }
          }
        }
        // if not selected: do nothing (so other letters in the word stay uncolored)
      } else {
        // diacritic inside the literal span (rare) is handled via inheritance above
      }
    }
  }
}

/// ---------- helpers ----------
class _Range {
  final int start, end;
  _Range(this.start, this.end);
}

List<int>? _parseIntList(dynamic v) {
  if (v is List) {
    final out = <int>[];
    for (final x in v) {
      final n = (x is int) ? x : int.tryParse(x.toString());
      if (n != null) out.add(n);
    }
    return out.isEmpty ? null : out;
  }
  return null;
}

List<String>? _parseStringList(dynamic v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  return null;
}

Color? _parseColor(dynamic s) {
  if (s == null) return null;
  var v = s.toString().trim();
  if (v.isEmpty) return null;
  if (v.startsWith('#')) v = v.substring(1);
  if (v.length == 6) v = 'FF$v';
  final n = int.tryParse(v, radix: 16);
  return n == null ? null : Color(n);
}

TextStyle? _parseTextStyle(dynamic raw) {
  if (raw == null) return null;
  if (raw is! Map) return null;
  final m = Map<String, dynamic>.from(raw);
  TextDecoration? dec;
  final d = m['decoration']?.toString();
  if (d != null && d.isNotEmpty) {
    final parts =
        d
            .split(RegExp(r'[\s,|]+'))
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toList();
    final list = <TextDecoration>[];
    for (final p in parts) {
      if (p == 'underline')
        list.add(TextDecoration.underline);
      else if (p == 'overline')
        list.add(TextDecoration.overline);
      else if (p == 'lineThrough' ||
          p == 'linethrough' ||
          p == 'strike' ||
          p == 'strikethrough') {
        list.add(TextDecoration.lineThrough);
      }
    }
    if (list.isNotEmpty) {
      dec = list.length == 1 ? list.first : TextDecoration.combine(list);
    }
  }

  FontWeight? fw;
  final fwRaw = m['fontWeight'] ?? m['font_weight'];
  if (fwRaw != null) {
    final s = fwRaw.toString().toLowerCase();
    const map = {
      'w100': FontWeight.w100,
      'thin': FontWeight.w100,
      'w200': FontWeight.w200,
      'extralight': FontWeight.w200,
      'w300': FontWeight.w300,
      'light': FontWeight.w300,
      'w400': FontWeight.w400,
      'regular': FontWeight.w400,
      'normal': FontWeight.w400,
      'w500': FontWeight.w500,
      'medium': FontWeight.w500,
      'w600': FontWeight.w600,
      'semibold': FontWeight.w600,
      'semi-bold': FontWeight.w600,
      'w700': FontWeight.w700,
      'bold': FontWeight.w700,
      'w800': FontWeight.w800,
      'extrabold': FontWeight.w800,
      'extra-bold': FontWeight.w800,
      'w900': FontWeight.w900,
      'black': FontWeight.w900,
    };
    fw =
        map[s] ??
        (() {
          final n = int.tryParse(s);
          if (n != null) {
            if (n <= 100) return FontWeight.w100;
            if (n <= 200) return FontWeight.w200;
            if (n <= 300) return FontWeight.w300;
            if (n <= 400) return FontWeight.w400;
            if (n <= 500) return FontWeight.w500;
            if (n <= 600) return FontWeight.w600;
            if (n <= 700) return FontWeight.w700;
            if (n <= 800) return FontWeight.w800;
            return FontWeight.w900;
          }
          return null;
        })();
  }

  final fsRaw = m['fontStyle'] ?? m['font_style'];
  final fs =
      (fsRaw != null && fsRaw.toString().toLowerCase().startsWith('i'))
          ? FontStyle.italic
          : null;

  return TextStyle(
    color: _parseColor(m['color']),
    backgroundColor: _parseColor(m['backgroundColor'] ?? m['background_color']),
    fontSize:
        (m['fontSize'] ?? m['font_size']) is num
            ? (m['fontSize'] ?? m['font_size']).toDouble()
            : null,
    fontWeight: fw,
    fontStyle: fs,
    height: (m['height'] is num) ? (m['height'] as num).toDouble() : null,
    letterSpacing:
        (m['letterSpacing'] is num)
            ? (m['letterSpacing'] as num).toDouble()
            : null,
    decoration: dec,
    decorationColor: _parseColor(m['decorationColor'] ?? m['decoration_color']),
    fontFamily: m['fontFamily']?.toString(),
  );
}

TextStyle? _composeStyle(TextStyle? style, Color? color) {
  if (style == null && color == null) return null;
  final s = style ?? const TextStyle();
  return (color != null) ? s.copyWith(color: color) : s;
}

/// Arabic combining marks
bool _isArabicDiacritic(int cu) {
  // 0610–061A, 064B–065F, 0670, 06D6–06ED, 08D3–08E1, 08E3–08FF
  return (cu >= 0x0610 && cu <= 0x061A) ||
      (cu >= 0x064B && cu <= 0x065F) ||
      (cu == 0x0670) ||
      (cu >= 0x06D6 && cu <= 0x06ED) ||
      (cu >= 0x08D3 && cu <= 0x08E1) ||
      (cu >= 0x08E3 && cu <= 0x08FF);
}
