import re

# Read file
with open('lib/screens/tracking/pre_trip_fromscreen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove .h and .w
content = re.sub(r'(\d+)\.h', r'\1', content)
content = re.sub(r'(\d+)\.w', r'\1', content)

# Replace sp(number) with ResponsiveHelper.spacing
def replace_sp(match):
    num = match.group(1)
    tablet = int(int(num) * 0.8)
    return f'ResponsiveHelper.spacing(context, mobile: {num}, tablet: {tablet})'

content = re.sub(r'sp\((\d+)\)', replace_sp, content)

# Replace fs(number) with ResponsiveHelper.font
def replace_fs(match):
    num = match.group(1)
    tablet = int(int(num) * 0.85)
    return f'ResponsiveHelper.font(context, mobile: {num}, tablet: {tablet})'

content = re.sub(r'fs\((\d+)\)', replace_fs, content)

# Write back
with open('lib/screens/tracking/pre_trip_fromscreen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed!")
