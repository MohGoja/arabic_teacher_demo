import 'package:arabic_teacher_demo/models/theme/custom_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FootnoteWidget extends StatelessWidget {
  final String widgetText;
  const FootnoteWidget({super.key, required this.widgetText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, right: 20, left: 20, bottom: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).extension<CustomColors>()!.lightBg,
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.rtl,
            children: [
              // Footnote icon
              Container(
                margin: const EdgeInsets.only(left: 12),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.blue.shade600,
                ),
              ),
              // Footnote text
              Expanded(
                child: Text(
                  widgetText,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.amiri(
                    fontSize: 15,
                    height: 1.6,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
