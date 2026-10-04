import os

file_path = r'c:\Users\DHANISHA IT S\Desktop\Her Area\backend\config\settings.py'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

target = "SECURE_SSL_REDIRECT = os.environ.get('SECURE_SSL_REDIRECT', 'False') == 'True'"
replacement = "SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')\n" + target

if "SECURE_PROXY_SSL_HEADER" not in content:
    content = content.replace(target, replacement)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Fixed!")
else:
    print("Already fixed!")
