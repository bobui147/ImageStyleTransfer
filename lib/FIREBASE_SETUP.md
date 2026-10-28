# Firebase profile + FCM

Ứng dụng đã được gắn với Firebase project `project-7180b607-0de7-493c-969` (My First Project). App Android là `com.example.login_api_bonus`. Email/Password Authentication, Realtime Database và Cloud Firestore đã được bật. Rules hiện hành chỉ cho UID của người dùng đã đăng nhập truy cập dữ liệu của chính họ.

## Dữ liệu

- Firebase Authentication: đăng ký/đăng nhập email và mật khẩu.
- Realtime Database: `users/{uid}/profile/{fullName,phone,address,updatedAt}` và `users/{uid}/fcmToken`.
- Cloud Firestore: `avatars/{uid}` chứa trường `bytes` kiểu Blob (JPEG tối đa 750 KB), `contentType`, `updatedAt`.
- Firebase Messaging: xin quyền thông báo, nhận FCM Token, cập nhật token khi thay đổi, lưu vào Realtime Database; thông báo khi app mở được hiện bằng SnackBar, thông báo nền do hệ điều hành hiển thị. Nút sao chép token giúp gửi thử đến thiết bị từ Firebase Console.

## Chạy project này

Từ thư mục gốc, chạy `flutter pub get` và `flutter run -d <android-device>`. Cấu hình Android nằm trong `android/app/google-services.json`; Gradle đã áp dụng plugin Google Services và manifest có quyền `INTERNET`, `POST_NOTIFICATIONS`.

Bạn có thể chạy Authentication, Realtime Database và Firestore trên web bằng `flutter run -d chrome`. FCM web cần thêm Web Push VAPID public key (`FIREBASE_WEB_VAPID_KEY`) và service worker của Firebase; bản này triển khai và kiểm tra FCM cho Android.

Nếu dùng **project Firebase khác**, chạy `flutterfire configure`, cập nhật các giá trị công khai trong `firebase_config.dart` (hoặc truyền qua `--dart-define-from-file`), thay `google-services.json`, rồi bật Email/Password và áp dụng rules tương ứng.

## Nếu chỉ nộp thư mục lib

Người chấm cần project Flutter với dependencies `firebase_core`, `firebase_auth`, `firebase_database`, `cloud_firestore`, `firebase_messaging`, `image_picker`, `image`, `http`, `flutter_svg`. Riêng Android FCM còn cần `android/app/google-services.json`, Google Services Gradle plugin và quyền thông báo trong manifest. Vì vậy thư mục `lib` chứa toàn bộ Dart code nhưng **không đủ để build độc lập** khi chép vào một project Flutter trống.
