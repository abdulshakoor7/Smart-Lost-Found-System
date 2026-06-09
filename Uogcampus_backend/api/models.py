from django.db import models
from django.contrib.auth.models import User

# ==========================================
# 1. USER PROFILE MODEL (New Privacy Update)
# ==========================================
class UserProfile(models.Model):
    # Links to the built-in Django User model
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    phone_number = models.CharField(max_length=15, blank=True, null=True)

    # ✅ THE PRIVACY TOGGLE FIELD: Persists user preference for the viva
    show_phone_to_finders = models.BooleanField(default=False)

    def __str__(self):
        return f"Profile for {self.user.username}"


# ==========================================
# 2. ITEM MODEL
# ==========================================
class Item(models.Model):
    STATUS_CHOICES = [
        ('PENDING', 'Pending Verification'),
        ('PUBLISHED', 'Published'),
        ('CLAIM_REQUESTED', 'Claim Requested'),
        ('MATCH_FOUND', 'Match Found'),
        ('VERIFIED', 'Verified'),
        ('REJECTED', 'Rejected'),
    ]

    TYPE_CHOICES = [
        ('LOST', 'Lost'),
        ('FOUND', 'Found'),
    ]

    title = models.CharField(max_length=200)
    category = models.CharField(max_length=100)
    description = models.TextField()
    location = models.CharField(max_length=200)
    date_reported = models.DateTimeField(auto_now_add=True)
    image = models.ImageField(upload_to='item_images/', blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    item_type = models.CharField(max_length=10, choices=TYPE_CHOICES)
    user_email = models.CharField(max_length=100, blank=True, null=True)
    ai_keywords = models.TextField(blank=True, null=True)
    claim_proof = models.TextField(blank=True, null=True)
    reported_by = models.ForeignKey(User, on_delete=models.CASCADE, null=True, blank=True)

    def __str__(self):
        return f"{self.item_type}: {self.title}"


# ==========================================
# 3. AUDIT LOG MODEL
# ==========================================
class AuditLog(models.Model):
    admin_email = models.EmailField()
    action = models.CharField(max_length=255)
    item_title = models.CharField(max_length=200)
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.action} by {self.admin_email}"


# ==========================================
# 4. ITEM GALLERY MODEL
# ==========================================
class ItemGallery(models.Model):
    item = models.ForeignKey(Item, related_name='gallery', on_delete=models.CASCADE)
    image = models.ImageField(upload_to='item_images/gallery/')

    def __str__(self):
        # Using string interpolation carefully to avoid IDE warnings
        return f"Gallery Image ID {self.id} for Item {self.item_id}"


# ==========================================
# 5. NOTIFICATION MODEL
# ==========================================
class Notification(models.Model):
    # Removed 'objects = None' to fix the manager error
    TYPES = (('MATCH', 'AI Match'), ('CHAT', 'Message'), ('CLAIM', 'Claim Update'))

    user_email = models.EmailField()
    title = models.CharField(max_length=100)
    message = models.TextField()
    notification_type = models.CharField(max_length=10, choices=TYPES, default='MATCH')
    target_id = models.IntegerField(null=True, blank=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Notify {self.user_email}: {self.title}"


# ==========================================
# 6. CLAIM MODEL (Cleaned & Consolidated)
# ==========================================
class Claim(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'Pending'),
        ('APPROVED', 'Approved'),
        ('REJECTED', 'Rejected')
    )

    # Consolidated fields: Removed duplicates that caused the redeclared warning
    item = models.ForeignKey(Item, on_delete=models.CASCADE, related_name='claims')
    claimant_email = models.EmailField()
    proof_description = models.TextField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        # Reference item_id for a warning-free string representation
        return f"Claim by {self.claimant_email} for Item {self.item_id}"