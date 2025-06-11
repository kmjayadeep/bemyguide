# GitHub Secrets Setup for Release APK Signing

To build properly signed release APKs in GitHub Actions, you need to configure the following secrets in your GitHub repository.

## 🔑 Required Secrets

Navigate to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

### 1. `RELEASE_KEYSTORE_BASE64`
This is your keystore file encoded in base64.

**To create this:**
```bash
# Encode your keystore file:
cat /home/jayadeep/private/android/upload-keystore.jks | base64 -w 0
```
Copy the entire output and paste it as the secret value.

### 2. `KEYSTORE_PASSWORD`
The password you used when creating the keystore (store password).

### 3. `KEY_PASSWORD`
The password for your key alias (key password).
- If you pressed ENTER when asked for key password, this is the SAME as your keystore password
- If you entered a different password, use that different password

### 4. `KEY_ALIAS`
The alias name for your key: `upload`

## 📋 Existing Secrets (Already Required)
Make sure you also have these secrets for your app functionality:
- `CLOUDFLARE_AI_BASE_URL`
- `CLOUDFLARE_AI_TOKEN`
- `CLOUDFLARE_AI_MODEL`

## 🚀 How It Works

### Debug Builds (Push to main/master)
- Uses debug signing (no secrets needed)
- Creates `app-debug.apk`
- Retained for 7 days

### Release Builds (Tags like v1.0.0)
- Uses your release keystore from secrets
- Creates properly signed `app-release.apk`
- Can be updated without uninstalling previous versions
- Attached to GitHub releases automatically

## 📱 Creating Your First Release

1. **Set up all secrets** listed above
2. **Tag your commit:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. **GitHub Actions will:**
   - Build a properly signed release APK
   - Create a GitHub release
   - Attach the APK to the release

## 🔒 Security Notes

- Never commit your keystore file to the repository
- The workflow automatically cleans up keystore files after the build
- Keep your keystore passwords secure and backed up
- If you lose your keystore, you won't be able to update your app on Play Store

## 🆘 Troubleshooting

**Build fails with "keystore not found":**
- Check that `RELEASE_KEYSTORE_BASE64` is correctly encoded
- Verify the base64 string has no newlines or spaces

**Build fails with "incorrect password":**
- Double-check `KEYSTORE_PASSWORD` and `KEY_PASSWORD`
- Make sure they match what you used when creating the keystore

**APK still can't be updated:**
- Make sure you're installing the release APK (from tagged builds)
- Debug APKs will still have the update issue 