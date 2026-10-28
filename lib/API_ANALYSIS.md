# Thông tin để nộp riêng thư mục lib

`main.dart` là điểm chạy. `login_page.dart` chứa giao diện và xử lý captcha. `auth_api.dart` chứa lệnh HTTP cho cả hai trang.

- Bonus 3.1: `POST https://securitymindset.ongbantat.io.vn/api/auth/login`, JSON gồm `username`, `password`, `captcha`. Captcha là phép tính được kiểm tra ngay trên giao diện. Thành công khi phản hồi có `status: true`.
- Bonus 3.2: `POST https://backend.ongbantat.io.vn/api/auth/create-captcha` để lấy `id` và SVG trong `data`. Sau khi người dùng nhập ký tự, gọi `POST https://backend.ongbantat.io.vn/api/auth/sign-in/account` với JSON `account`, `password`, `captcha: "id|ký_tự"`. Hai request dùng headers `api-version: public` và `Authorization: customer`. Thành công khi HTTP 200 và phản hồi có `token`.

Nếu dán `lib` vào project khác, cần thêm dependencies `http: ^1.6.0` và `flutter_svg: ^2.3.0` vào `pubspec.yaml`, rồi chạy `flutter pub get`. Android cần `<uses-permission android:name="android.permission.INTERNET" />` trong manifest.
