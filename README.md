# 番茄鐘 Pomodoro Timer

Material Design 3 的跨平台番茄鐘，用 Flutter 寫，一套程式碼跑 **Android / iOS / Windows / macOS / Linux / Web**。

倉庫裡另外保留了一版 WinUI 3 實作（見最下方）。

## 功能

- 專注 / 短休息 / 長休息三階段自動循環，每 N 個番茄接一次長休息
- Material 3 配色：預設跟隨系統動態色彩（Android 12+），關閉後整個介面配色會隨階段變換（紅／綠／藍），並以 `AnimatedTheme` 平滑過渡
- 自繪的圓環倒數（`CustomPainter`），從 12 點鐘方向順時針推進
- 循環進度圓點，一眼看出這輪還差幾個番茄
- 開始 / 暫停 / 繼續、重設本階段、跳過階段、重設今日進度
- 可調整各階段長度、長休息間隔、自動接續、提示音、震動回饋
- 桌面鍵盤快速鍵：`Space` 開始／暫停、`R` 重設
- 深色模式自動跟隨系統
- 設定用 shared_preferences 保存，各平台都寫進原生偏好設定

倒數以「結束時刻」為基準計算，而不是累加 tick，所以背景分頁被節流、手機忙碌造成 timer 延遲時，時間也不會愈跑愈偏。

## 執行

需要 Flutter 3.24 以上（Dart 3.5+）。開發時實測過的版本是 **Flutter 3.47.1 / Dart 3.13.1**。

```bash
cd app

# 產生各平台的原生專案資料夾（android/ios/windows/macos/linux/web）
flutter create . --project-name pomodoro --platforms=android,ios,windows,macos,linux,web

flutter pub get
flutter run            # 跑在預設裝置
flutter run -d chrome  # 或指定平台：chrome / windows / macos / linux / <device-id>
```

> 倉庫只放跨平台的 Dart 原始碼，平台資料夾由 `flutter create .` 產生，這樣不必把各平台的 Gradle / Xcode 樣板檔一起版控。`flutter create .` 不會覆蓋既有的 `lib/`、`test/` 與 `pubspec.yaml` 內容。

測試（9 個：計時邏輯 5 個 + 畫面 4 個）：

```bash
cd app && flutter test
```

打包：

```bash
flutter build apk          # Android
flutter build windows      # Windows
flutter build macos        # macOS
flutter build web          # Web
```

> Web 版預設會從 Google 的 CDN 抓 CanvasKit 與中文備援字型。若部署環境連不到外網，改用 `flutter build web --release --no-web-resources-cdn` 把 CanvasKit 打包進去；中文字型則需要自行 bundle 一份 Noto Sans TC 到 `pubspec.yaml` 的 assets。

## 驗證狀態

以 Flutter 3.47.1 實測：`flutter analyze` 無任何問題、`flutter test` 9 項全過、`flutter build web --release` 編譯成功，並在無頭 Chromium 裡實際跑過（淺色／深色、階段換色、圓環推進都正確）。

## 專案結構

```
app/
├── pubspec.yaml
├── lib/
│   ├── main.dart                     App 進入點、動態色彩、主題切換
│   ├── theme.dart                    MD3 配色：階段色 + harmonize
│   ├── pomodoro_controller.dart      計時與階段循環（ChangeNotifier）
│   ├── models/pomodoro_settings.dart 設定資料模型
│   ├── services/settings_store.dart  shared_preferences 存取
│   ├── screens/timer_screen.dart     主畫面
│   ├── screens/settings_screen.dart  設定畫面
│   └── widgets/progress_ring.dart    自繪圓環
└── test/pomodoro_controller_test.dart
```

## 預設值

| 項目 | 預設 |
| --- | --- |
| 專注 | 25 分鐘 |
| 短休息 | 5 分鐘 |
| 長休息 | 15 分鐘 |
| 長休息間隔 | 每 4 個番茄 |
| 自動開始休息 | 開 |
| 休息後自動開始專注 | 關 |

## WinUI 3 版本（保留）

`src/PomodoroTimer/` 與 `PomodoroTimer.sln` 是同一個番茄鐘的 WinUI 3（Windows App SDK + .NET 8）實作，功能相同但只跑在 Windows，並多了系統 Toast 通知與視窗置頂。用 Visual Studio 2022 開啟 sln、平台選 x64 後按 F5 即可。不需要的話可以整個刪掉。

## 授權

見 [LICENSE](LICENSE)。
