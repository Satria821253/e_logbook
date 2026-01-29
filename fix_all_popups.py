import re

files = [
    'lib/screens/documents/nahkoda/nahkoda_document_popup.dart',
    'lib/screens/documents/crew/crew_pending_popup.dart',
    'lib/screens/documents/nahkoda/nahkoda_pending_popup.dart'
]

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Add import if not exists
    if 'responsive_helper' not in content:
        content = content.replace(
            "import 'package:flutter/material.dart';",
            "import 'package:flutter/material.dart';\nimport 'package:e_logbook/utils/responsive_helper.dart';"
        )
    
    # Fix all hardcoded values
    replacements = [
        ('height: 600,', 'height: ResponsiveHelper.popupHeight(context),'),
        ('height: 525,', 'height: ResponsiveHelper.popupHeight(context, mobile: 525, smallTablet: 450, mediumTablet: 480, largeTablet: 525),'),
        ('margin: const EdgeInsets.symmetric(horizontal: 24),', 'margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.popupPadding(context)),'),
        ('constraints: const BoxConstraints(maxWidth: 450),', 'constraints: BoxConstraints(maxWidth: ResponsiveHelper.popupMaxWidth(context)),'),
        ('borderRadius: BorderRadius.circular(32),', 'borderRadius: BorderRadius.circular(ResponsiveHelper.popupBorderRadius(context)),'),
        ('padding: const EdgeInsets.all(24),', 'padding: EdgeInsets.all(ResponsiveHelper.popupPadding(context)),'),
        ('const SizedBox(height: 24),', 'SizedBox(height: ResponsiveHelper.spacing(context, mobile: 24, tablet: 20)),'),
        ('const SizedBox(height: 12),', 'SizedBox(height: ResponsiveHelper.spacing(context, mobile: 12, tablet: 10)),'),
        ('const SizedBox(height: 32),', 'SizedBox(height: ResponsiveHelper.spacing(context, mobile: 32, tablet: 24)),'),
        ('fontSize: 28,', 'fontSize: ResponsiveHelper.popupTitleSize(context),'),
        ('fontSize: 26,', 'fontSize: ResponsiveHelper.popupTitleSize(context, mobile: 26, smallTablet: 20, mediumTablet: 22, largeTablet: 24),'),
        ('fontSize: 15,', 'fontSize: ResponsiveHelper.popupSubtitleSize(context),'),
        ('fontSize: 16,', 'fontSize: ResponsiveHelper.font(context, mobile: 16, tablet: 14),'),
        ('fontSize: 20,', 'fontSize: ResponsiveHelper.font(context, mobile: 20, tablet: 16),'),
        ('fontSize: 14,', 'fontSize: ResponsiveHelper.font(context, mobile: 14, tablet: 12),'),
        ('width: 160,\n      height: 160,', 'width: ResponsiveHelper.popupIllustrationSize(context),\n      height: ResponsiveHelper.popupIllustrationSize(context),'),
        ('width: 200,\n      height: 200,', 'width: ResponsiveHelper.popupIllustrationSize(context, mobile: 200, smallTablet: 150, mediumTablet: 170, largeTablet: 190),\n      height: ResponsiveHelper.popupIllustrationSize(context, mobile: 200, smallTablet: 150, mediumTablet: 170, largeTablet: 190),'),
        ('width: 100,\n                height: 100,', 'width: ResponsiveHelper.popupLottieSize(context),\n                height: ResponsiveHelper.popupLottieSize(context),'),
        ('width: 120,\n              height: 120,', 'width: ResponsiveHelper.popupLottieSize(context, mobile: 120, smallTablet: 90, mediumTablet: 100, largeTablet: 110),\n              height: ResponsiveHelper.popupLottieSize(context, mobile: 120, smallTablet: 90, mediumTablet: 100, largeTablet: 110),'),
        ('padding: const EdgeInsets.symmetric(vertical: 16),', 'padding: EdgeInsets.symmetric(\n            horizontal: ResponsiveHelper.width(context, mobile: 24, tablet: 20),\n            vertical: ResponsiveHelper.height(context, mobile: 16, tablet: 14),\n          ),'),
        ('const Text(\n                        \'Selamat Datang, Nahkoda!\',', 'Text(\n                        \'Selamat Datang, Nahkoda!\','),
        ('const Text(\n                              \'Lengkapi dokumen kepelayaran Anda untuk memulai perjalanan\',', 'Text(\n                              \'Lengkapi dokumen kepelayaran Anda untuk memulai perjalanan\','),
        ('const Text(\n                        \'Sedang Diproses\',', 'Text(\n                        \'Sedang Diproses\','),
        ('const Text(\n                        \'Dokumen Sedang Diverifikasi\',', 'Text(\n                        \'Dokumen Sedang Diverifikasi\','),
        ('width: double.infinity,\n      child: ElevatedButton(', 'width: double.infinity,\n      height: ResponsiveHelper.popupButtonHeight(context),\n      child: ElevatedButton('),
    ]
    
    for old, new in replacements:
        content = content.replace(old, new)
    
    with open(file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Fixed {file}")

print("All popups fixed!")
