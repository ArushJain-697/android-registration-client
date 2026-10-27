# SAJEEV on the Android Registration Client: clean-machine setup

This fork (`sajeev/liveness`, base MOSIP `develop` 6e1943c) refuses to store or accept a face unless the SAJEEV engine
says the capture is live and bound to the person in front of the camera. On a clean machine the app BUILDS only after
step 1, and it CAPTURES a face only after steps 2 and 3. Without them every face capture is refused (fail closed). That
is correct behaviour, but it looks like a broken product, so follow all steps.

Paths below are in the main SAJEEV repo (`sajeev/`) unless noted.

## 1. Build the engine AAR and put it in the client

The client compiles against `android/app/libs/sajeev-engine.aar` (`implementation files('libs/sajeev-engine.aar')`).
The AAR is not committed. Without it the build fails at compile time with missing `io.sajeev.*` imports.

```
cd sajeev
mvn -pl liveness-api,liveness-core -DskipTests package          # JDK 11, makes the two engine jars
cd integrations/engine-android
sh prepare.sh                                                   # copies the jars (and the androidTest models)
gradle --offline :engine:assembleRelease                        # Gradle 8.5, JDK 17
cp engine/build/outputs/aar/engine-release.aar <this fork>/android/app/libs/sajeev-engine.aar
```

Then, in this fork, with Flutter 3.10.x: `sh pigeon.sh`, `flutter gen-l10n`, `flutter build apk --debug`.
(The pigeon and l10n outputs are git-ignored.)

## 2. Provide the model files

The engine reads its models from the app's private directory `files/models` (`<app filesDir>/models`). It loads them only
after the ECDSA-signed `manifest.txt` + `manifest.sig` verify against the trust root bundled in the engine, and every
file's SHA-256 matches. A model without a valid signature is refused. The models are NOT in git (see
`liveness-models/README.md` for their licences, and note the MiniFASNet weights have no stated licence).

Get them: `sajeev/scripts/fetch_models.sh` (downloads the model zip, checks its SHA-256, unpacks to
`sajeev/liveness-models/models`: `manifest.txt`, `manifest.sig`, `yunet/`, `landmark/`, `minifasnet/`, `sface/`).

Two ways to put them on the device:

* **Bundle (recommended, automatic).** Copy the directory into the app assets before building:
  `mkdir -p android/app/src/main/assets/sajeev-models && cp -R liveness-models/models/* android/app/src/main/assets/sajeev-models/`.
  On the first start the engine (`ModelProvisioner`, in the AAR) copies exactly the files that `manifest.txt` lists, plus
  the manifest and signature, to `files/models`. It copies again only if the bundled manifest differs from the installed
  one. Nothing is downloaded at run time. The copy is not trusted: verification still runs on the copied files.
* **adb push (debug builds).**
  ```
  adb push liveness-models/models /data/local/tmp/sajeev-models
  adb shell run-as io.mosip.registration_client mkdir -p files
  adb shell run-as io.mosip.registration_client cp -R /data/local/tmp/sajeev-models files/models
  ```

If the models are missing or fail verification the engine is UNAVAILABLE for the whole session and the person sees
"could not be verified". Nothing is stored.

## 3. The frame feed: the patched mock SBI

Passive and challenge liveness need video frames. The client does not open the camera itself: the SBI (the device
service) owns it. A stock MOSIP SBI has no way to hand frames to another app. SAJEEV adds a frame feed to the
android-camera-mds MockAndroidSBI: `integrations/patches/0003-mockandroidsbi-frame-feed.patch`, branch
`sajeev/frame-feed` of android-camera-mds.

* The feed is a bound service `io.mosip.mock.sbi.feed.FrameFeedService`, protected by the signature-level permission
  `io.mosip.mock.sbi.permission.FRAME_FEED`. A **signature** permission is granted only if the SBI and the client are
  signed with the **same key**. Sign both with the same keystore (the debug key works if both are debug builds from the
  same machine).
* **Install order: SBI first, then the client.** The client's `uses-permission` (merged from the AAR manifest) is only
  granted at install time if the permission already exists. If you installed the client first, uninstall it and install
  it again after the SBI.
* The SBI also needs its device keystore (`mosipface.p12`) set up to sign Info and rCapture; see
  `integrations/README.md`, "Driving the Android mock on the emulator".
* The mock feed replays files or synthetic frames (`mock:true` in the device info). It is NOT a camera. A LIVE verdict
  from the mock stack proves the pipeline works, not that a real person was in front of a real camera. The client labels
  such sessions "mock" in the liveness dialog.

## 4. A real SBI without the feed: LIMITED (capture-only)

With a real vendor SBI (no feed service) the engine cannot see a video stream. The session is **LIMITED**: it can look
only at the final captured still image (face quality and a single-image presentation-attack check), not at motion or
challenges, and it can never bind the capture to a live session. The Java gate treats LIMITED as not live:
`checkCapture` returns false, so **no face is stored** and the dialog says the device cannot verify liveness. That is
deliberate: a still-image check alone is exactly what a printed photo defeats. To use a real SBI in production it
needs the feed (or a certified liveness/PAD in the SBI itself, which MOSIP's own SBI spec leaves to the vendor). An
administrator can switch the whole feature off with the server global parameter
`mosip.registration.liveness.enabled=false`; that setting is server-only (a local preference cannot change it) and
everything then behaves like upstream MOSIP.

## 5. Settings (global parameters, from the server)

All keys start with `mosip.registration.liveness.` and come from the server sync only; the client refuses local
overrides and UI writes of these keys. Defaults: `enabled=true`, `maxRetries=3`, `passive.threshold=0.80`,
`faceAuth.enabled=false` (face login and approval are off until switched on; password login is unchanged).
Face authentication (login, packet authentication, approval) locks a user out of the FACE route for 5 minutes after
`maxRetries` failed attempts; the password route stays available.

## 6. Checks

```
flutter test --dart-define=FLUTTER_FONTS=<flutter>/bin/cache/artifacts/material_fonts test/liveness test/liveness_events_test.dart
cd android && ./gradlew :clientmanager:testDebugUnitTest --tests '*FaceAuthLockoutTest' --tests '*LivenessSettingsTest' --tests '*LocalConfigDAOLivenessTest'
```

Note: the upstream `clientmanager` test source set at base 6e1943c does not compile as a whole (eight old test files
use stale constructors). To run the SAJEEV tests, move those files aside temporarily; this is not caused by SAJEEV.
