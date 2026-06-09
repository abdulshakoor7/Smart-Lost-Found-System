from rest_framework import serializers
from .models import Item, ItemGallery, Notification

class ItemGallerySerializer(serializers.ModelSerializer):
    class Meta:
        model = ItemGallery
        fields = ['image']

class ItemSerializer(serializers.ModelSerializer):
    reported_by_email = serializers.ReadOnlyField(source='reported_by.email')
    gallery = ItemGallerySerializer(many=True, read_only=True)

    # ✅ NEW FIELDS: These map directly to the logic in your Flutter ItemDetailScreen
    owner_phone = serializers.SerializerMethodField()
    owner_show_phone = serializers.SerializerMethodField()

    class Meta:
        model = Item
        fields = '__all__'

    # Logic to fetch the phone number from the User's Profile
    def get_owner_phone(self, obj):
        try:
            if obj.reported_by and hasattr(obj.reported_by, 'profile'):
                return obj.reported_by.profile.phone_number
        except:
            return None
        return None

    # Logic to fetch the privacy toggle from the User's Profile
    def get_owner_show_phone(self, obj):
        try:
            if obj.reported_by and hasattr(obj.reported_by, 'profile'):
                return obj.reported_by.profile.show_phone_to_finders
        except:
            return False
        return False

class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = '__all__'