# Google Sign-In Integration for Stew Step

Expand the user authentication system to support **Google Sign-In** alongside the existing email/password login and registration.

## User Review Required

> [!IMPORTANT]
> **Google Sign-In Client Platform Configurations:**
> For Google Sign-In to function on Android and Web:
> 1. On Web: The Google Client ID must be configured in Google Developer Console and can be passed to `GoogleSignIn(clientId: ...)` if running on localhost/web.
> 2. On Android: The SHA-1 fingerprint of the debug signing key must be added to the Firebase project settings, and the updated `google-services.json` must be placed in the project.
> 
> **Branding & Logo:**
> - We will use the existing **`font_awesome_flutter`** package to show a styled Google logo icon.
> - The Google button will be styled as a clean white card with a subtle border and the Google icon/text, or a royal blue outline matching the Stew Step branding.

---

## Proposed Changes

### 1. Dependencies

#### [MODIFY] [pubspec.yaml](file:///e:/projects/login/pubspec.yaml)
- Add `google_sign_in: ^6.2.1`

---

### 2. Localization

#### [MODIFY] [en.json](file:///e:/projects/login/assets/translations/en.json)
- Add keys:
  - `"continue_with_google": "Continue with Google"`
  - `"or_divider": "OR"`

#### [MODIFY] [ar.json](file:///e:/projects/login/assets/translations/ar.json)
- Add corresponding Arabic translations:
  - `"continue_with_google": "المتابعة باستخدام جوجل"`
  - `"or_divider": "أو"`

---

### 3. Authentication Service

#### [MODIFY] [auth_service.dart](file:///e:/projects/login/lib/core/services/auth_service.dart)
- Add `signInWithGoogle()`:
  - Initialize `GoogleSignIn`.
  - Sign in the user with Google.
  - Obtain auth credentials and sign in to Firebase Auth.
  - Check if a user document with the UID already exists in the Firestore `users` collection.
  - If it does **not** exist (new user), create a new document with:
    - `uid`: Google user UID
    - `name`: Google display name
    - `email`: Google email
    - `createdAt`: server timestamp
  - Return the `UserCredential`.

---

### 4. UI Modifications

#### [MODIFY] [login_screen.dart](file:///e:/projects/login/lib/features/auth/login_screen.dart)
- Add a visual divider ("OR") below the Login button.
- Add a "Continue with Google" button matching the Stew Step style.
- Wrap Google Sign-In with the `_isLoading` state spinner.

#### [MODIFY] [register_screen.dart](file:///e:/projects/login/lib/features/auth/register_screen.dart)
- Add the same divider and "Continue with Google" button below the Register button.
- Wrap Google Sign-In with the `_isLoading` state spinner.

---

## Verification Plan

### Automated Verification
- Run `flutter analyze` to ensure clean compile state.

### Manual Verification
1. Launch the web app using `flutter run -d chrome`.
2. Tap "Continue with Google" on `LoginScreen`.
3. Complete the Google authentication flow.
4. Verify redirection to `MainScaffold`.
5. Check Firestore `users` collection to confirm that:
   - For a first-time Google user, a document is created with their name, email, and timestamp.
   - For a returning Google user, the document is NOT overwritten (preserving the original timestamp).
