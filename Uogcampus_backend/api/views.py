import math
import logging
import smtplib
from django.conf import settings
from django.core.mail import send_mail
from django.db.models import Q
from django.db import transaction
from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes # Added api_view and permission_classes
from rest_framework.permissions import AllowAny # Added AllowAny
from rest_framework.response import Response
from rest_framework.authtoken.models import Token # Added Token
from django.contrib.auth.models import User # Added User

# Removed unused ItemGallery to clear warnings
from .models import Item, Notification, Claim, AuditLog, UserProfile
from .serializers import ItemSerializer, NotificationSerializer
from .ai_service import extract_image_tags

logger = logging.getLogger(__name__)

# ==========================================
# ✅ NEW BRIDGE LOGIC: Firebase Sync
# ==========================================
@api_view(['POST'])
@permission_classes([AllowAny]) # Anyone can attempt to sync
def firebase_sync(request):
    """
    Takes the email from a successful Firebase login and generates
    or retrieves a Django Token for that user.
    """
    email = request.data.get('email')
    # Use email as username for Django consistency
    user, created = User.objects.get_or_create(username=email, email=email)

    # Ensure a Profile exists
    UserProfile.objects.get_or_create(user=user)

    # Generate or Get the Django Token
    token, _ = Token.objects.get_or_create(user=user)

    return Response({
        "token": token.key,
        "email": user.email
    })

# ==========================================
# 1. ITEM VIEWSET
# ==========================================
class ItemViewSet(viewsets.ModelViewSet):
    # Defining the queryset clearly helps remove 'unresolved attribute' warnings
    queryset = Item.objects.all().order_by('-date_reported')
    serializer_class = ItemSerializer

    # ✅ ACTION: update_privacy
    @action(detail=False , methods=['post'])
    def update_privacy(self, request):
        # ✅ LOGIC: Ensure user is logged in
        if not request.user.is_authenticated:
            return Response({"error": "Authentication required"}, status=status.HTTP_401_UNAUTHORIZED)

        try:
            # ✅ FIX: Get or Create ensures no 404/500 if profile is missing
            profile, created = UserProfile.objects.get_or_create(user=request.user)

            # Use .get() to avoid KeyErrors
            show_phone = request.data.get('show_phone', False)
            profile.show_phone_to_finders = show_phone
            profile.save()

            return Response({"status": "Privacy updated successfully"}, status=200)
        except Exception as e:
            logger.error(f"❌ Privacy Update Error: {str(e)}")
            return Response({"error": str(e)}, status=400)

    def perform_create(self, serializer):
        """
        The 'Brain' of the system: Saves items and executes the
        Smart Matching Engine for multiple users.
        """
        with transaction.atomic():
            new_item = serializer.save()

        # 1. AI Image Analysis
        ai_tags = []
        if new_item.image:
            try:
                ai_tags = extract_image_tags(new_item.image.path)
                new_item.ai_keywords = ", ".join(ai_tags)
                new_item.save()
            except Exception as e:
                logger.error(f"AI Error: {e}")

        # 2. Multi-User Matching Logic
        target_type = 'FOUND' if new_item.item_type == 'LOST' else 'LOST'
        candidates = Item.objects.filter(
            item_type=target_type,
            category=new_item.category
        ).exclude(status__in=['CLAIMED', 'VERIFIED'])

        matched_users_emails = []

        for candidate in candidates:
            score = self.calculate_similarity(new_item, candidate, ai_tags)

            if score >= 60:
                candidate.status = 'MATCH_FOUND'
                candidate.save()
                new_item.status = 'MATCH_FOUND'
                new_item.save()

                # Notify existing candidate
                Notification.objects.create(
                    user_email=new_item.user_email,
                    title="🎉 Match Found!",
                    message=f"Someone reported an item matching your '{candidate.title}'!",
                    notification_type='MATCH',
                    target_id=candidate.id
                )

                # Notify the person who just uploaded
                Notification.objects.create(
                    user_email=new_item.user_email,
                    title="🎉 Match Found!",
                    message=f"A matching item for '{new_item.title}' is already in our records!",
                    notification_type='MATCH',
                    target_id=candidate.id
                )

                if candidate.user_email:
                    matched_users_emails.append(candidate.user_email)

        if matched_users_emails:
            self.send_bulk_match_emails(new_item.title, matched_users_emails)

    @staticmethod
    def calculate_similarity(new_item, candidate, ai_tags):
        score = 0
        cand_tags = (candidate.ai_keywords or "").lower().split(", ")
        if any(tag in cand_tags for tag in ai_tags): score += 40

        new_keys = set(new_item.title.lower().split())
        cand_keys = set(candidate.title.lower().split())
        if new_keys.intersection(cand_keys): score += 40

        if new_item.location == candidate.location: score += 20
        return score

    @staticmethod
    def send_bulk_match_emails(item_title, email_list):
        try:
            send_mail(
                "Smart Campus: Match Detected!",
                f"Our AI has found potential matches for: {item_title}. Check the app.",
                settings.DEFAULT_FROM_EMAIL,
                email_list,
                fail_silently=False
            )
        except (smtplib.SMTPException, Exception) as e:
            logger.error(f"Bulk Email Error: {e}")

    @action(detail=False, methods=['post'])
    def smart_search(self, request):
        query = request.data.get('query', '').lower()
        results = Item.objects.filter(Q(title__icontains=query) | Q(description__icontains=query))
        return Response(self.get_serializer(results, many=True).data)

    @action(detail=True, methods=['post'])
    def found_it(self, request, pk=None):
        try:
            item = self.get_object()
            finder_email = request.data.get('finder_email')

            owner_email = getattr(item, 'user_email', None) or getattr(item.user, 'email', None)

            if owner_email == finder_email:
                return Response({"error": "You are the owner of this item"}, status=status.HTTP_400_BAD_REQUEST)

            Notification.objects.create(
                user_email=owner_email,
                title="🔍 Item Located!",
                message=f"Good news! Someone found your '{item.title}'.",
                notification_type='MATCH',
                target_id=item.id
            )

            print(f"✅ Notification successfully sent to {owner_email}")
            return Response({"status": "Owner Notified"}, status=status.HTTP_200_OK)
        except Exception as e:
            logger.error(f"❌ CRITICAL ERROR in found_it: {str(e)}")
            return Response({"error": "A server error occurred."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @action(detail=True, methods=['post'])
    def claim_item(self, request, pk=None):
        item = self.get_object()
        email = request.data.get('claimant_email')
        proof = request.data.get('proof')

        Claim.objects.create(
            item=item,
            claimant_email=email,
            proof_description=proof
        )

        item.status = 'CLAIM_REQUESTED'
        item.save()
        return Response({"status": "Claim Submitted"}, status=status.HTTP_201_CREATED)
        Notification.objects.create(
            user_email="admin@uog.edu.pk",
            title="⚖️ New Claim Request",
            message=f"Item '{item.title}' has been claimed by {email}.",
            notification_type='CLAIM',
            target_id=item.id
        )


    @action(detail=False, methods=['post'])
    def chat_alert(self, request):
        receiver_email = request.data.get('receiver_email')
        sender_name = request.data.get('sender_name')
        item_id = request.data.get('item_id')

        Notification.objects.create(
            user_email=receiver_email,
            title="💬 New Message",
            message=f"{sender_name} sent you a message.",
            notification_type='CHAT',
            target_id=item_id
        )
        return Response({"status": "Alert Created"}, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def verify_claim(self, request, pk=None):
        item = self.get_object()
        claim_id = request.data.get('claim_id')

        try:
            claim = Claim.objects.get(id=claim_id)
            claim.status = 'APPROVED'
            claim.save()

            item.status = 'RESOLVED'
            item.save()

            Notification.objects.create(
                user_email=claim.claimant_email,
                title="✅ Claim Verified!",
                message=f"Your claim for '{item.title}' has been approved.",
                notification_type='MATCH',
                target_id=item.id
            )

            send_mail(
                "UOG Lost & Found: Item Verified",
                f"Hello,\n\nYour claim for '{item.title}' has been verified.\n\nRegards,\nCampus Security",
                settings.DEFAULT_FROM_EMAIL,
                [claim.claimant_email],
                fail_silently=False,
            )

            AuditLog.objects.create(
                admin_email=request.data.get('admin_email', 'Admin'),
                action=f"Approved Claim ID {claim_id} for Item {item.title}"
            )

            return Response({"status": "Success"}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ==========================================
# 2. NOTIFICATION VIEWSET
# ==========================================
class NotificationViewSet(viewsets.ModelViewSet):
    queryset = Notification.objects.all()
    serializer_class = NotificationSerializer

    def get_queryset(self):
        email = self.request.query_params.get('email')
        if email:
            return Notification.objects.filter(user_email=email).order_by('-created_at')
        return Notification.objects.none()

    @action(detail=True, methods=['patch'])
    def mark_as_read(self, request, pk=None):
        notification = self.get_object()
        notification.is_read = True
        notification.save()
        return Response({"status": "read"}, status=status.HTTP_200_OK)

    @action(detail=False, methods=['post'])
    def trigger_chat_notification(self, request):
        sender_name = request.data.get('sender_name')
        receiver_email = request.data.get('receiver_email')
        item_id = request.data.get('item_id')
        msg_text = request.data.get('message_text')

        Notification.objects.create(
            user_email=receiver_email,
            title=f"💬 Message from {sender_name}",
            message=f"{msg_text[:30]}...",
            notification_type='CHAT',
            target_id=item_id,
            is_read=False
        )
        return Response({"status": "Chat Alert Created"}, status=status.HTTP_201_CREATED)