import os
import sys
import django

# Setup Django environment
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from django.core.mail import send_mail
from django.conf import settings

def send_test_email(recipient_email):
    print(f"Using EMAIL_BACKEND: {settings.EMAIL_BACKEND}")
    print(f"Connecting to SMTP Server: {settings.EMAIL_HOST}:{settings.EMAIL_PORT}")
    print(f"Sender: {settings.DEFAULT_FROM_EMAIL}")
    print(f"Sending test email to: {recipient_email}")
    
    try:
        sent_count = send_mail(
            subject='HER AREA SMTP Test',
            message='This is a test email from the HER AREA Django backend.',
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[recipient_email],
            fail_silently=False,
        )
        
        if sent_count > 0:
            print(f"\n[SUCCESS] Test email successfully delivered via ZeptoMail to {recipient_email}!")
        else:
            print("\n[WARNING] send_mail returned 0, meaning the email was not sent, but no exception was raised.")
            
    except Exception as e:
        print(f"\n[ERROR] Failed to send email.")
        print(f"Error Type: {type(e).__name__}")
        print(f"Error Message: {str(e)}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python test_smtp.py <recipient_email>")
        sys.exit(1)
        
    recipient = sys.argv[1]
    send_test_email(recipient)
