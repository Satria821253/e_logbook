import re

file = 'lib/screens/documents/crew/crew_document_popup.dart'

with open(file, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
content = content.replace(
    "import 'package:flutter/material.dart';\nimport 'dart:ui';",
    "import 'package:flutter/material.dart';\nimport 'package:e_logbook/utils/responsive_helper.dart';\nimport 'dart:ui';"
)

# Fix all hardcoded values
replacements = [
    ('height: 600,', 'height: ResponsiveHelper.popupHeight(context),'),
    ('margin: const EdgeInsets.symmetric(horizontal: 24),', 'margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.popupPadding(context)),'),
    ('constraints: const BoxConstraints(maxWidth: 450),', 'constraints: BoxConstraints(maxWidth: ResponsiveHelper.popupMaxWidth(context)),'),
    ('borderRadius: BorderRadius.circular(32),', 'borderRadius: BorderRadius.circular(ResponsiveHelper.popupBorderRadius(context)),'),
    ('padding: const EdgeInsets.all(24),', 'padding: EdgeInsets.all(ResponsiveHelper.popupPadding(context)),'),
    ('const SizedBox(height: 24),', 'SizedBox(height: ResponsiveHelper.spacing(context, mobile: 24, tablet: 20)),'),
    ('const SizedBox(height: 12),', 'SizedBox(height: ResponsiveHelper.spacing(context, mobile: 12, tablet: 10)),'),
    ('const SizedBox(height: 32),', 'SizedBox(height: ResponsiveHelper.spacing(context, mobile: 32, tablet: 24)),'),
    ('fontSize: 28,', 'fontSize: ResponsiveHelper.popupTitleSize(context),'),
    ('fontSize: 15,', 'fontSize: ResponsiveHelper.popupSubtitleSize(context),'),
    ('fontSize: 16,', 'fontSize: ResponsiveHelper.font(context, mobile: 16, tablet: 14),'),
    ('width: 200,\n      height: 200,', 'width: ResponsiveHelper.popupIllustrationSize(context),\n      height: ResponsiveHelper.popupIllustrationSize(context),'),
    ('size: 100,', 'size: ResponsiveHelper.popupLottieSize(context),'),
    ('padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),', 'padding: EdgeInsets.symmetric(\n            horizontal: ResponsiveHelper.width(context, mobile: 48, tablet: 40),\n            vertical: ResponsiveHelper.height(context, mobile: 18, tablet: 16),\n          ),'),
    ('borderRadius: BorderRadius.circular(30),', 'borderRadius: BorderRadius.circular(ResponsiveHelper.borderRadius(context, mobile: 30, tablet: 24)),'),
    ('const Text(\n                        \'Ahoy, Crew!\',', 'Text(\n                        \'Ahoy, Crew!\','),
    ('const Text(\n                        \'Siapkan dokumen Anda untuk bergabung dalam pelayaran\',', 'Text(\n                        \'Siapkan dokumen Anda untuk bergabung dalam pelayaran\','),
    ('const Text(\n          \'Lengkapi Dokumen\',', 'Text(\n          \'Lengkapi Dokumen\','),
    ('width: double.infinity,\n      child: ElevatedButton(', 'width: double.infinity,\n      height: ResponsiveHelper.popupButtonHeight(context),\n      child: ElevatedButton('),
]

for old, new in replacements:
    content = content.replace(old, new)

with open(file, 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed crew_document_popup.dart")
