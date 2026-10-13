import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.conf import settings
import requests

token = settings.ZEPTOMAIL_SEND_MAIL_TOKEN

urls = [
    'https://api.zeptomail.com/v1.1/email',
    'https://api.zeptomail.in/v1.1/email',
    'https://api.zeptomail.eu/v1.1/email',
    'https://api.zeptomail.com.au/v1.1/email'
]

payload = {
    'from': {'address': 'noreply@herarea.com', 'name': 'HER AREA Admin'},
    'to': [{'email_address': {'address': 'admin@herarea.com'}}],
    'subject': 'Diagnostic Test',
    'htmlbody': '<p>Test</p>'
}

headers = {
    "Accept": "application/json", 
    "Content-Type": "application/json", 
    "Authorization": f"Zoho-enczapikey {token}"
}

for u in urls:
    try:
        response = requests.post(u, headers=headers, json=payload, timeout=10)
        print(f"URL: {u}")
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}\n")
    except Exception as e:
        print(f"URL: {u} - Failed: {e}\n")
