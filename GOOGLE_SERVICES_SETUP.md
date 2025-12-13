# Google Services Setup for Android

## After downloading google-services.json from Firebase:

1. Place the file here:
   ```
   android/app/google-services.json
   ```

2. Uncomment this line in android/app/build.gradle.kts (line 8):
   ```kotlin
   id("com.google.gms.google-services")
   ```

3. Run:
   ```bash
   flutter clean
   flutter pub get
   cd android && ./gradlew clean
   cd ..
   flutter run
   ```

## Verify google-services.json Content

Your google-services.json should contain:
- package_name: "com.gameofcreators.mobile"
- Your OAuth client IDs
- Your project number: 942484778913

## Important Notes

- For DEBUG builds, use SHA-1: 7E:9B:3A:01:BE:28:41:00:7F:05:D8:EE:15:B6:82:79:01:60:56:CD
- For RELEASE builds, you'll need to generate a new SHA-1 from your release keystore
- google-services.json is optional for Google Sign-In if you're using serverClientId
- Make sure NOT to commit google-services.json to git (it's already in .gitignore)
