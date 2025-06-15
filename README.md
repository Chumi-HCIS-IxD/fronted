# 教學平台 Flutter 專案

本專案為一個教學平台前端，使用 Flutter 開發，整合 Firebase Auth 與 Firestore，可實作使用者註冊／登入、顯示課程資訊等功能。

---

## 🔧 如何測試

### ✅ 啟動專案

建議使用 Chrome 瀏覽器執行本專案：

```bash
flutter run -d chrome
```

### ✅ 測試帳號密碼

你可以使用以下測試帳密登入：

```
Email：test@example.com
Password：123456
```

或點擊「還沒有帳號？點我註冊」自行創建帳號。

### ✅ 註冊流程

1. 點擊登入畫面底部的「還沒有帳號？點我註冊」。
2. 填入姓名、Email 與密碼後，點選「註冊」按鈕。
3. 註冊成功後會自動導回登入頁面。
4. 登入成功後將跳轉至主畫面。

---

## 🔐 Firebase 功能

- **Firebase Auth**：負責使用者帳密登入／註冊與驗證。
- **Cloud Firestore**：使用者註冊後，會將個人資訊儲存到 `users/{uid}` 文件中。

### 🧾 Firestore 使用者資料結構

每位使用者在 `users/{uid}` 文件下會有以下欄位：

```json
{
  "name": "測試使用者",
  "email": "test@example.com",
  "createdAt": "自動生成的時間戳記"
}
```

---

## 📦 資料儲存（SharedPreferences）

登入後的 Firebase Token 將會儲存至本機的 `SharedPreferences`，下次開啟 App 時會自動判斷是否已登入。

---

## 📁 專案結構（部分）

```
lib/
├── pages/
│   ├── login_page.dart        # 登入頁面
│   ├── register_page.dart     # 註冊頁面
│   └── home_page.dart         # 主畫面
├── widgets/
│   └── course_info_card.dart  # 課程卡片元件
├── auth/
│   └── firebase_auth_service.dart  # Firebase Auth 封裝
└── firebase_options.dart      # flutterfire configure 自動產生
```

---

## 📌 注意事項

- 若出現 Firestore 權限錯誤，請確認 Firebase Console 中 Firestore 的安全規則是否允許讀寫。
- 建議測試時開啟 Firebase 模擬器或將 Firestore 規則設為開放（僅限測試環境）。
