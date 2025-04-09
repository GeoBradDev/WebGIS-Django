from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import CustomUser, AdoptedArea


class CustomUserAdmin(UserAdmin):
    model = CustomUser
    list_display = ('email', 'username', 'is_staff', 'is_active')
    list_filter = ('is_staff', 'is_active')
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('Personal Info', {'fields': ('username',)}),
        ('Permissions', {'fields': ('is_staff', 'is_active', 'groups', 'user_permissions')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'username', 'password1', 'password2', 'is_staff', 'is_active')}
         ),
    )
    search_fields = ('email', 'username')
    ordering = ('email',)


class AdoptedAreaAdmin(admin.ModelAdmin):
    model = AdoptedArea
    list_display = ['user', 'email', 'city', 'state', 'country', 'created_at']
    search_fields = ['email', 'city', 'state', 'country']
    list_filter = ['state', 'country', 'created_at']
    readonly_fields = ('created_at',)

admin.site.register(AdoptedArea, AdoptedAreaAdmin)
admin.site.register(CustomUser, CustomUserAdmin)

