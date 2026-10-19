import re
import logging
from django.db.models import Q
from apps.accounts.models import User, UserRole

logger = logging.getLogger('her_area')

def normalize_email(email: str) -> str:
    """Normalize email address to lowercase and trimmed."""
    if not email:
        return ""
    return email.strip().lower()

def normalize_phone_number(phone: str) -> str:
    """
    Extracts raw digits and strips international/country code prefixes (e.g. +91 or 91 or leading 0).
    Returns the core 10-digit mobile number for Indian numbers, or cleaned digits.
    """
    if not phone:
        return ""
    digits = re.sub(r'\D', '', str(phone).strip())
    if digits.startswith('91') and len(digits) == 12:
        return digits[2:]
    if digits.startswith('0') and len(digits) == 11:
        return digits[1:]
    return digits

def get_phone_candidates(phone: str, raw_input: str = None) -> list:
    """
    Generates all plausible database representations of a phone number.
    Ensures matching regardless of whether the stored record has '+91', '91', '0', or 10 digits.
    """
    candidates = set()
    if raw_input:
        raw_clean = str(raw_input).strip()
        if raw_clean:
            candidates.add(raw_clean)
            
    if phone:
        p_clean = str(phone).strip()
        if p_clean:
            candidates.add(p_clean)
        
        digits = re.sub(r'\D', '', p_clean)
        if digits:
            candidates.add(digits)
            core = digits
            if digits.startswith('91') and len(digits) == 12:
                core = digits[2:]
            elif digits.startswith('0') and len(digits) == 11:
                core = digits[1:]
                
            if len(core) == 10:
                candidates.add(core)
                candidates.add(f"+91{core}")
                candidates.add(f"+91 {core}")
                candidates.add(f"91{core}")
                candidates.add(f"0{core}")

    return list(candidates)

def find_user_by_identifier(identifier: str, role: str = None):
    """
    Finds a User by identifier (email or phone number), optionally scoped to a specific role.
    Handles lookups against both User model and VendorProfile model.
    Returns a tuple of (user, is_email).
    """
    if not identifier:
        return None, False
        
    raw_str = str(identifier).strip()
    is_email = '@' in raw_str
    
    # Avoid circular import
    from apps.vendors.models import VendorProfile
    
    if is_email:
        clean_email = normalize_email(raw_str)
        if role:
            # First match direct User record
            user = User.objects.filter(role=role, email__iexact=clean_email).first()
            if user:
                return user, True
                
            # If looking for VENDOR, check VendorProfile official_email
            if role == UserRole.VENDOR:
                vp = VendorProfile.objects.filter(official_email__iexact=clean_email).select_related('user').first()
                if vp and vp.user and vp.user.role == UserRole.VENDOR:
                    return vp.user, True
            return None, True
        else:
            # Role unconstrained
            user = User.objects.filter(email__iexact=clean_email).first()
            if not user:
                vp = VendorProfile.objects.filter(official_email__iexact=clean_email).select_related('user').first()
                if vp and vp.user:
                    user = vp.user
            return user, True
    else:
        norm_phone = normalize_phone_number(raw_str)
        candidates = get_phone_candidates(norm_phone, raw_input=raw_str)
        
        if role:
            # First match direct User record
            user = User.objects.filter(role=role, phone_number__in=candidates).first()
            if user:
                return user, False
                
            # If looking for VENDOR, check VendorProfile phone_number
            if role == UserRole.VENDOR:
                vp = VendorProfile.objects.filter(phone_number__in=candidates).select_related('user').first()
                if vp and vp.user and vp.user.role == UserRole.VENDOR:
                    return vp.user, False
            return None, False
        else:
            # Role unconstrained
            user = User.objects.filter(phone_number__in=candidates).first()
            if not user:
                vp = VendorProfile.objects.filter(phone_number__in=candidates).select_related('user').first()
                if vp and vp.user:
                    user = vp.user
            return user, False
