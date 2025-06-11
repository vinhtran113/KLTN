# Fitness Workout App

**Fitness Workout App** là ứng dụng hỗ trợ quản lý tập luyện, dinh dưỡng, theo dõi tiến trình sức khỏe cá nhân và nhiều tính năng hữu ích khác dành cho người dùng yêu thích thể thao và chăm sóc sức khỏe.

## Tính năng nổi bật

- Đăng ký, đăng nhập, quản lý hồ sơ cá nhân
- Lập lịch tập luyện, nhắc nhở và theo dõi lịch sử tập luyện
- Quản lý chế độ ăn uống, tóm tắt dinh dưỡng, thống kê calo
- Theo dõi và so sánh ảnh tiến trình (body progress)
- Thống kê sức khỏe, biểu đồ hoạt động, hỗ trợ đa ngôn ngữ, dark mode

## Hướng dẫn cài đặt

### 1. Yêu cầu

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Android Studio hoặc VS Code (cài plugin Flutter & Dart)
- Đã cài đặt Git

### 2. Clone dự án

```sh
git clone https://github.com/vinhtran113/KLTN.git
cd fitness_workout_app
```

### 3. Cài đặt các package phụ thuộc

```sh
flutter pub get
```

### 4. Thiết lập Firebase

- Tải file `google-services.json` (Android) và đặt vào `android/app/`
- Tải file `GoogleService-Info.plist` (iOS) và đặt vào `ios/Runner/`
- (Nếu có sử dụng `.env`, tạo file `.env` ở thư mục gốc và điền các biến môi trường cần thiết)

### 5. Chạy ứng dụng

```sh
flutter run
```

### 6. Một số lệnh hữu ích

- Kiểm tra lỗi code: `flutter analyze`
- Chạy unit test: `flutter test`
- Build APK: `flutter build apk`

## Đóng góp & Hỗ trợ

Nếu gặp lỗi hoặc cần hỗ trợ, hãy tạo issue trên GitHub hoặc liên hệ với nhóm phát triển.

---

**Chúc bạn sử dụng ứng dụng hiệu quả!**
