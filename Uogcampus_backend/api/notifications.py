from django.core.mail import send_mail
from firebase_admin import messaging

def send_match_notification(user_email, fcm_token, item_name):
    # --- 1. Send SMTP Email ---
    subject = f"Match Found: Your {item_name} might have been found!"
    message = f"Hello,\n\nOur AI system has detected a potential match for your lost '{item_name}'. Please open the Campus Lost & Found app to review the match and contact the finder.\n\nRegards,\nCampus Security"

    try:
        send_mail(subject, message, None, [user_email])
    except Exception as e:
        print(f"Email Error: {e}")

    # --- 2. Send Firebase Push Notification ---
    if fcm_token:
        message = messaging.Message(
            notification=messaging.Notification(
                title='Match Found! 🔍',
                body=f'Someone found an item matching your {item_name}.',
            ),
            token=fcm_token,
        )
        try:
            messaging.send(message)
        except Exception as e:
            print(f"FCM Error: {e}")