# Preparation of presentation — WasteJustice Flutter (Waste Collector)

Use this to show your lecturer you understand **your own** project, not only that it runs.

---

## 1. How to prove you built it yourself (demo + talking points)

1. **Open the project in Android Studio / VS Code** and show `lib/` — walk file by file and say what each does (table below).
2. **Show `pubspec.yaml`** — name your dependencies (`http`, `geolocator`, `hive_flutter`, `firebase_messaging`, `flutter_local_notifications`, etc.) and **why** each is there.
3. **Change one small thing live** (e.g. a `Text` on `HomePage` or a colour in `ThemeData`) — hot reload — proves you know the entry flow.
4. **Explain one full user journey in code:**  
   Login → token saved → `DashboardPage` → `get_collections` / `get_earnings` with `Authorization: Bearer` → submit waste in `pages.dart` → optional offline queue → `PendingSubmissionSync`.
5. **Show API base URL** in `lib/api_config.dart` and say you pointed the app at **your** deployed PHP API.
6. **Local side:** open `offline_storage.dart` and explain Hive keys (`userCredentials`, `pendingCollectionSubmissions`, `knownPaidPaymentIds`).
7. **Notifications:** open `notification.dart` — local notifications + FCM listener; say submission success calls `notifyWasteSubmissionSent` from `pages.dart`.

---

## 2. Quick map of your Dart files

| File | Your one-line explanation |
|------|---------------------------|
| `main.dart` | `WidgetsFlutterBinding`, Firebase (non-web), Hive init, `NotificationService.instance.init()`, `runApp`. |
| `api_config.dart` | Base URL and path builders for `auth/`, `waste/`, `payments/`, `aggregators/`, `pricing/`. |
| `api_service.dart` | `http` GET/POST, JSON decode, Bearer token from storage, `submitCollection`, `getCollections`, `getEarnings`, photo multipart upload. |
| `offline_storage.dart` | Hive box `wasteJusticeBox`: credentials, pending submissions, cached prices, known payment IDs for notifications. |
| `pending_submission_sync.dart` | When online, drains queue: upload photo → `submitCollection` → optional notification → remove from queue. |
| `login_page.dart` | POST `login.php`, parse JSON, `saveUserCredentials`, navigate to dashboard. |
| `dashboard_page.dart` | Loads collections + earnings, refresh, offline banner, payment “Paid” column, new-payment local notifications, `WidgetsBindingObserver` resume refresh. |
| `pages.dart` | Aggregators, plastic types, location, waste form, `submitCollection`, offline enqueue with `plasticTypeName`. |
| `notification.dart` | FCM permission/token, `flutter_local_notifications`, haptics, payment + submission alerts. |
| `firebase_options.dart` | Generated Firebase project IDs (from FlutterFire). |
| `home_page.dart` | Landing UI, navigation to login / flows. |

---

## 3. Likely lecturer questions — general Flutter

**Q: What is the difference between `StatelessWidget` and `StatefulWidget`?**  
**A:** `StatelessWidget` has no mutable state after build. `StatefulWidget` owns a `State` object; you call `setState()` to rebuild when data changes (e.g. loading flag, form fields).

**Q: What does `async` / `await` do in Flutter?**  
**A:** They let you wait for futures (network, file I/O) without freezing the UI thread, as long as you don’t block the isolate. After `await`, check `mounted` before `setState` if the widget might be disposed.

**Q: What is `BuildContext`?**  
**A:** Handle to the widget’s location in the tree; used for `Navigator`, `Theme`, `MediaQuery`, `ScaffoldMessenger`.

**Q: Why `MaterialApp`?**  
**A:** Provides Material Design theming, routing, and default text direction; your app sets `theme` and `home`.

**Q: How does navigation work in your app?**  
**A:** Imperative: `Navigator.push`, `pushReplacement`, `pushAndRemoveUntil` with `MaterialPageRoute` to open `LoginPage`, `DashboardPage`, `pages.dart` screens.

---

## 4. Likely lecturer questions — your app (network & auth)

**Q: How does the app talk to the server?**  
**A:** Package `http`. URLs from `ApiConfig`. JSON bodies for POST; `Authorization: Bearer <token>` header where `ApiService` reads the token from Hive via `OfflineStorageService.getUserCredentials()`.

**Q: Where is the JWT (or token) stored?**  
**A:** In Hive, key `userCredentials` — `userId`, `token`, optional `userName` — saved after successful login in `login_page.dart`.

**Q: What if the server returns HTML instead of JSON?**  
**A:** `ApiService._decodeJsonResponse` checks for HTML / empty body and throws a clear `Exception` so the UI can show a useful error.

**Q: How is a waste submission sent?**  
**A:** Optional `upload_collection_photo.php` multipart upload for the image path, then `submit_collection.php` with plastic type, weight, lat/lng, location, notes, optional `aggregatorID`.

---

## 5. Local resources — questions & answers

*(“Local resources” = data and services on the device: storage, files, notifications, config files.)*

**Q: What local database or storage does your app use?**  
**A:** **Hive** (`hive` + `hive_flutter`). The box name is `wasteJusticeBox`, opened in `main.dart` after `Hive.initFlutter()`.

**Q: What exactly do you store locally in Hive?**  
**A:**  
- `userCredentials` — logged-in user id, API token, display name.  
- `pendingCollectionSubmissions` — list of maps for waste queued when offline (weight, coords, `localPhotoPath`, `plasticTypeName`, etc.).  
- `pendingRequests` / `cachedPrices` — other cached or queued data per `offline_storage.dart`.  
- `knownPaidPaymentIds` — list of payment IDs already notified so new completed payments trigger one local notification each.

**Q: Why not only use `shared_preferences`?**  
**A:** Hive is efficient for structured lists (e.g. many pending submissions) and typed boxes; the project still documents the pattern clearly in one service class.

**Q: Where are payment receipts saved on the phone?**  
**A:** `path_provider` → `getApplicationDocumentsDirectory()` in `dashboard_page.dart`; a `.txt` file is written with amount, date, collection info.

**Q: What are “local notifications” in your app?**  
**A:** `flutter_local_notifications` shows system tray notifications from Dart code — e.g. after successful waste submit (`notifyWasteSubmissionSent`) and when a new completed payment appears in earnings (`notifyNewCompletedPayment`). Vibration/haptics are configured in `notification.dart`.

**Q: What is Firebase used for?**  
**A:** `firebase_core` + `firebase_messaging` for **push** capability: FCM token, foreground `onMessage`, background handler registered in `main.dart`. If the server sends a message later, the app can show it; submission/payment alerts also work **without** server push via local notifications.

**Q: What is `google-services.json`?**  
**A:** Android Firebase config placed under `android/app/`; Gradle uses it so the app can connect to your Firebase project.

**Q: What is `lib/firebase_options.dart`?**  
**A:** Generated file (FlutterFire CLI) with `FirebaseOptions` per platform so `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` works.

**Q: Which Android permissions relate to “local” device features?**  
**A:** In `AndroidManifest.xml`: e.g. `CAMERA`, storage (where used), `INTERNET`, location, `POST_NOTIFICATIONS`, `VIBRATE` — for photos, maps, notifications, and vibration.

**Q: Does the app work offline?**  
**A:** Partially: if submit fails with a network-type error, `pages.dart` can **enqueue** a pending submission; when the user opens the dashboard online, `PendingSubmissionSync.flushAll()` sends queued items and can show a success notification.

**Q: Are there local image files before upload?**  
**A:** Yes — `image_picker` gives a local path (`XFile` / `File`); that path is stored in the offline queue as `localPhotoPath` until upload succeeds.

**Q: What local resources are **not** in your repo secrets-wise?**  
**A:** You should be honest: Firebase keys in `google-services.json` / `firebase_options.dart` identify your Firebase project; treat them as project-specific config, not passwords. API base URL in `api_config.dart` is public by nature (HTTPS endpoint).

---

## 6. “Trick” questions — short honest answers

**Q: Did you write every line from scratch?**  
**A:** Flutter/Firebase **boilerplate** (e.g. `firebase_options.dart`, Gradle) is tooling-generated; **your** logic is in `api_service`, `pages`, `dashboard_page`, `offline_storage`, `notification`, `pending_submission_sync`.

**Q: What was the hardest part?**  
**A:** Pick one you actually did: e.g. offline queue + sync, multipart photo upload, JSON error handling, or matching PHP API field names (`plasticTypeID`, `collectionID`).

**Q: How would you test this?**  
**A:** Manual: login, list collections, submit with airplane mode on/off, pull-to-refresh dashboard; check Hive in debug; verify notification permission on Android 13+.

---

## 7. One-minute “elevator” script (memorise)

“I built a Flutter client for waste collectors. It logs in against our PHP API, stores the token in Hive, and loads the dashboard from REST endpoints. Collectors can pick an aggregator, choose plastic type and weight, capture GPS and photos, and submit — or queue offline and sync later. I used local notifications and optional FCM for feedback when a submission is sent or a payment appears in earnings. Configuration lives in `api_config.dart` and Firebase files for Android.”

---

*File created for your WasteJustice collector app under `mobileappwastecollector`. Adjust any answer if you change the code or API URL.*
