from django.core.mail import send_mail
from fcm_django.models import FCMDevice # If using fcm-django package

def notify_user_of_match(user_email, item_name, user_fcm_token):
    # 1. Send Email
    send_mail(
        'Smart Lost & Found: Match Found!',
        f'Good news! A potential match for your "{item_name}" has been found on campus. Check the app for details.',
        'from@uog.edu.pk',
        [user_email],
        fail_silently=False,
    )

    # 2. Send In-App Notification (FCM)
    device = FCMDevice.objects.get(registration_id=user_fcm_token)
    device.send_message(title="Match Found!", body=f"Someone found your {item_name}!")