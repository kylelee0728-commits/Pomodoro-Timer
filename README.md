# 番茄鐘 Pomodoro Timer（WinUI 3）

用 WinUI 3 / Windows App SDK 寫的桌面番茄鐘，MVVM 架構、單一視窗、設定會自動保存。

![結構](https://img.shields.io/badge/WinUI-3-blue) ![.NET](https://img.shields.io/badge/.NET-8-purple)

## 功能

- 專注 / 短休息 / 長休息三階段自動循環，每 N 個番茄接一次長休息
- 手繪圓環倒數（從 12 點鐘方向順時針推進），依階段換色
- 開始 / 暫停 / 繼續、重設本階段、跳過此階段、重設今日進度
- 可調整各階段長度、長休息間隔、是否自動接續下一階段
- 階段結束時的提示音與系統通知（Toast）
- 視窗永遠置頂選項
- 設定寫入 `%LocalAppData%\PomodoroTimer\settings.json`，下次開啟自動沿用

倒數是以「結束時刻」為基準計算，而不是累加 tick，所以即使系統忙碌造成 timer 延遲，時間也不會愈跑愈偏。

## 執行環境

- Windows 10 1809 (17763) 以上
- .NET 8 SDK
- Visual Studio 2022，安裝「**Windows 應用程式開發**」工作負載（含 Windows App SDK）

## 建置與執行

用 Visual Studio 開啟 `PomodoroTimer.sln`，把 `PomodoroTimer` 設為啟動專案，選 `x64`（或 `ARM64`）後按 F5。

命令列：

```powershell
dotnet build PomodoroTimer.sln -c Debug -p:Platform=x64
```

打包成 MSIX：

```powershell
dotnet publish src\PomodoroTimer\PomodoroTimer.csproj -c Release -p:Platform=x64 -p:RuntimeIdentifier=win-x64
```

> 這是 single-project MSIX（打包型）應用程式。系統通知需要打包執行才會出現；未打包執行時通知會自動略過，其他功能不受影響。

## 專案結構

```
PomodoroTimer.sln
src/PomodoroTimer/
├── App.xaml(.cs)              應用程式進入點，註冊通知
├── MainWindow.xaml(.cs)       主畫面：自訂標題列 + 計時畫面 + 設定側欄
├── Controls/
│   └── RingProgress.xaml(.cs) 自繪的圓環進度控制項
├── Converters/
│   └── IntDoubleConverter.cs  NumberBox(double) ↔ 設定(int)
├── Services/
│   ├── PomodoroSettings.cs    設定資料模型
│   ├── SettingsService.cs     JSON 讀寫
│   ├── NotificationService.cs Toast 通知
│   └── SoundService.cs        提示音
├── ViewModels/
│   ├── PomodoroPhase.cs       階段列舉
│   └── TimerViewModel.cs      計時、階段循環、設定綁定
├── Assets/                    App 圖示
└── Package.appxmanifest       MSIX 資訊清單
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

## 授權

見 [LICENSE](LICENSE)。
