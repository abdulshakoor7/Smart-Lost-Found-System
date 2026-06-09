from django.contrib import admin
from .models import Item, Notification, Claim  # Add Claim here

@admin.register(Claim)
class ClaimAdmin(admin.ModelAdmin):
    # What the admin sees in the table
    list_display = ('item', 'claimant_email', 'status', 'created_at')
    # Admin can filter by status (Pending/Approved)
    list_filter = ('status',)
    # Admin can search by email or item name
    search_fields = ('claimant_email', 'item__title')
    # Ability to change status directly from the list
    list_editable = ('status',)