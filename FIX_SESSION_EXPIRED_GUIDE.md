# 🔧 Fix "Session Expired" Error - Step-by-Step Guide

## Problem Summary
You're getting a red "Session expired. Please log in again" error when trying to update your profile, even though you're logged in.

## Root Causes Identified
1. ❌ **Missing PKCE Auth Flow** - Sessions weren't persisting properly
2. ❌ **Missing RLS Policies** - Database rejecting profile updates
3. ❌ **No Auto-Profile Creation** - New users don't get profile rows automatically

---

## ✅ SOLUTION (Follow in Order)

### Step 1: Update Flutter App (DONE ✓)

The following changes have been made to your Flutter code:

1. **main.dart** - Added PKCE authentication flow:
   ```dart
   authOptions: const FlutterAuthClientOptions(
     authFlowType: AuthFlowType.pkce,
     localStorage: SecureLocalStorage(),
   )
   ```

2. **user_profile_page.dart** - Added debug logging and better error handling:
   - Debug prints to track session state
   - Better distinction between network errors vs session expiry
   - Retry option for failed profile loads

---

### Step 2: Run SQL in Supabase (YOU MUST DO THIS)

1. **Open Supabase Dashboard**: https://app.supabase.com
2. **Navigate to**: SQL Editor (left sidebar)
3. **Click**: "New Query"
4. **Copy the entire file**: `SUPABASE_RLS_AND_TRIGGERS.sql`
5. **Paste and Run** all the SQL commands

This will:
- ✅ Enable Row Level Security
- ✅ Create 3 policies (SELECT, INSERT, UPDATE)
- ✅ Add trigger to auto-create profiles on signup
- ✅ Create profiles for existing users without them

---

### Step 3: Restart Your App

```powershell
# Stop the current app (Ctrl+C in terminal)
# Then run:
flutter clean
flutter pub get
flutter run
```

---

## 🔍 How to Verify It Works

After restarting your app:

1. **Check Terminal Output**:
   ```
   🔍 DEBUG - Load Profile:
     AuthProvider User: your@email.com
     Supabase User ID: xxx-xxx-xxx-xxx
     Database Response: Found
   ```

2. **Edit Your Profile**:
   - Tap the edit icon
   - Change your name
   - Click "Save Changes"
   - You should see: ✓ Profile updated successfully (green)

3. **No More Red Errors**: The "Session expired" bar should never appear unless you actually log out.

---

## 🐛 Still Getting Errors?

### If you see "Session expired" STILL:

1. **Check Supabase Logs**:
   - Dashboard > Logs > API Logs
   - Look for 403 errors or RLS failures

2. **Temporarily Disable RLS** (Testing Only):
   ```sql
   ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;
   ```
   - If it works now → RLS policies need adjustment
   - Remember to re-enable: `ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;`

3. **Check Debug Output**: The terminal will now show:
   ```
   🔍 DEBUG - Update Profile:
     AuthProvider User: your@email.com
     Supabase User ID: xxx-xxx-xxx-xxx
   ```
   - If "Supabase User ID" is null → Session actually expired
   - If it has a value → Database permission issue

---

## 📋 What Changed in Your Code

### main.dart
- Added `authOptions` with PKCE flow for persistent sessions

### user_profile_page.dart
- Added debug logging to `_loadUserProfile()` and `_updateProfile()`
- Better error handling (network errors vs session expiry)
- Retry button for failed loads

### Database (SQL file)
- RLS policies for secure user profile access
- Auto-create trigger for new user profiles
- Verification queries to check setup

---

## 🎯 Expected Behavior After Fix

1. **Login**: Session stays active for 7 days
2. **Profile Load**: Always shows your data (even if some fields are empty)
3. **Profile Update**: Saves immediately with green success message
4. **Network Error**: Orange warning with "Retry" button (not "Session expired")
5. **Actual Session Expiry**: Only after 7 days or manual logout

---

## 💡 Tips

- The debug prints (🔍 DEBUG) will be removed in production
- Keep the SQL file (`SUPABASE_RLS_AND_TRIGGERS.sql`) for reference
- If you add new users, the trigger auto-creates their profiles
- RLS keeps each user's profile private (they can only see/edit their own)

---

**After completing Step 2 (running the SQL), restart your Flutter app and test!**
