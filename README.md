# Flutter API login và Firebase profile

Ứng dụng Flutter gồm hai luồng đăng nhập API Bonus 3.1/3.2 và một luồng Firebase Authentication, profile, avatar Firestore, FCM. Chạy bằng `flutter pub get` rồi `flutter run`.

Mã Dart nằm trong [`lib`](lib). Xem [`lib/FIREBASE_SETUP.md`](lib/FIREBASE_SETUP.md) để biết cấu hình Android và các dependencies cần có nếu chép riêng `lib`.

## Phân tích API

| Hệ thống | Bước | Request | Dữ liệu chính | Kết quả |
| --- | --- | --- | --- | --- |
| Security Mindset | Đăng nhập | `POST https://securitymindset.ongbantat.io.vn/api/auth/login` | JSON `username`, `password`, `captcha` | HTTP 200, `status: true` là thành công |
| Ông Bán Tất | Lấy captcha | `POST https://backend.ongbantat.io.vn/api/auth/create-captcha` | JSON `{}`; header `api-version: public`, `Authorization: customer` | `id` và `data` chứa SVG |
| Ông Bán Tất | Đăng nhập | `POST https://backend.ongbantat.io.vn/api/auth/sign-in/account` | JSON `account`, `password`, `captcha` theo dạng `id|nội_dung`; cùng headers trên | HTTP 200 và `token` là thành công; lỗi captcha trả HTTP 400 và `message` |

Security Mindset tạo phép tính captcha và kiểm tra đáp án trong JavaScript ở trình duyệt trước khi gửi request. Bản Flutter làm tương tự. Ông Bán Tất dùng captcha do backend phát hành, nên ứng dụng phải lấy mới và hiển thị SVG; khi đăng nhập lỗi sẽ lấy lại captcha.

Mã nguồn không nhúng sẵn tài khoản hay mật khẩu test. Token đăng nhập của Ông Bán Tất chỉ dùng để nhận biết đăng nhập thành công và không được lưu lâu dài; bài tập không yêu cầu gọi API sau đăng nhập.

## Kiểm tra

`flutter analyze` và `flutter test`.
