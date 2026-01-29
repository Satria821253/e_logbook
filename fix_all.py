import re
import os

files = [
    'lib/widgets/custom_text_field.dart',
    'lib/widgets/date_time_picker.dart',
    'lib/screens/notification_screen.dart'
]

for file_path in files:
    if not os.path.exists(file_path):
        print(f"Skip {file_path} - not found")
        continue
        
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Remove import
    content = re.sub(r"import 'package:flutter_screenutil/flutter_screenutil\.dart';\r?\n", '', content)
    
    # Remove .h, .w, .r, .sp
    content = re.sub(r'(\d+)\.h', r'\1', content)
    content = re.sub(r'(\d+)\.w', r'\1', content)
    content = re.sub(r'(\d+)\.r', r'\1', content)
    content = re.sub(r'(\d+)\.sp', r'\1', content)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Fixed: {file_path}")

print("Done!")
