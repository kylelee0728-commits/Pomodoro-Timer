using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Media;
using PomodoroTimer.Services;

namespace PomodoroTimer.ViewModels;

/// <summary>
/// Drives the whole app: the countdown, the focus/break cycle, and the persisted settings.
/// The countdown is anchored to a wall-clock deadline rather than accumulated ticks, so it
/// stays accurate even when timer ticks are delayed.
/// </summary>
public partial class TimerViewModel : ObservableObject
{
    private readonly PomodoroSettings _settings;
    private readonly DispatcherTimer _ticker;

    private DateTimeOffset _deadline;
    private TimeSpan _remaining;
    private bool _loadingSettings;

    [ObservableProperty]
    private PomodoroPhase phase = PomodoroPhase.Focus;

    [ObservableProperty]
    private bool isRunning;

    [ObservableProperty]
    private int completedFocusSessions;

    public TimerViewModel()
    {
        _settings = SettingsService.Load();

        _loadingSettings = true;
        FocusMinutes = _settings.FocusMinutes;
        ShortBreakMinutes = _settings.ShortBreakMinutes;
        LongBreakMinutes = _settings.LongBreakMinutes;
        LongBreakInterval = _settings.LongBreakInterval;
        AutoStartBreaks = _settings.AutoStartBreaks;
        AutoStartFocus = _settings.AutoStartFocus;
        PlaySound = _settings.PlaySound;
        ShowNotifications = _settings.ShowNotifications;
        AlwaysOnTop = _settings.AlwaysOnTop;
        _loadingSettings = false;

        _remaining = DurationFor(Phase);

        _ticker = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(200) };
        _ticker.Tick += OnTick;
    }

    #region Settings

    [ObservableProperty]
    private int focusMinutes;

    [ObservableProperty]
    private int shortBreakMinutes;

    [ObservableProperty]
    private int longBreakMinutes;

    [ObservableProperty]
    private int longBreakInterval;

    [ObservableProperty]
    private bool autoStartBreaks;

    [ObservableProperty]
    private bool autoStartFocus;

    [ObservableProperty]
    private bool playSound;

    [ObservableProperty]
    private bool showNotifications;

    [ObservableProperty]
    private bool alwaysOnTop;

    partial void OnFocusMinutesChanged(int value) => OnDurationSettingChanged(v => _settings.FocusMinutes = v, value);

    partial void OnShortBreakMinutesChanged(int value) => OnDurationSettingChanged(v => _settings.ShortBreakMinutes = v, value);

    partial void OnLongBreakMinutesChanged(int value) => OnDurationSettingChanged(v => _settings.LongBreakMinutes = v, value);

    partial void OnLongBreakIntervalChanged(int value)
    {
        _settings.LongBreakInterval = value;
        PersistSettings();
        OnPropertyChanged(nameof(CycleText));
    }

    partial void OnAutoStartBreaksChanged(bool value) => PersistFlag(v => _settings.AutoStartBreaks = v, value);

    partial void OnAutoStartFocusChanged(bool value) => PersistFlag(v => _settings.AutoStartFocus = v, value);

    partial void OnPlaySoundChanged(bool value) => PersistFlag(v => _settings.PlaySound = v, value);

    partial void OnShowNotificationsChanged(bool value) => PersistFlag(v => _settings.ShowNotifications = v, value);

    partial void OnAlwaysOnTopChanged(bool value) => PersistFlag(v => _settings.AlwaysOnTop = v, value);

    private void OnDurationSettingChanged(Action<int> apply, int value)
    {
        apply(value);
        PersistSettings();

        // While idle, a new duration should show on the clock immediately.
        if (!IsRunning)
        {
            ResetCurrentPhase();
        }
    }

    private void PersistFlag(Action<bool> apply, bool value)
    {
        apply(value);
        PersistSettings();
    }

    private void PersistSettings()
    {
        if (_loadingSettings)
        {
            return;
        }

        SettingsService.Save(_settings);
    }

    #endregion

    #region Presentation

    public string TimeText
    {
        get
        {
            var remaining = _remaining < TimeSpan.Zero ? TimeSpan.Zero : _remaining;
            // Round up so the clock shows 25:00 for a full 25 minute session.
            var total = (int)Math.Ceiling(remaining.TotalSeconds);
            return $"{total / 60:00}:{total % 60:00}";
        }
    }

    public double Progress
    {
        get
        {
            var total = DurationFor(Phase).TotalSeconds;
            if (total <= 0)
            {
                return 0;
            }

            var elapsed = total - Math.Max(_remaining.TotalSeconds, 0);
            return Math.Clamp(elapsed / total, 0, 1);
        }
    }

    public string PhaseTitle => Phase switch
    {
        PomodoroPhase.Focus => "專注中",
        PomodoroPhase.ShortBreak => "短休息",
        _ => "長休息",
    };

    public string PhaseHint => Phase switch
    {
        PomodoroPhase.Focus => "關掉通知，只做一件事。",
        PomodoroPhase.ShortBreak => "站起來、看遠方、喝口水。",
        _ => "好好離開座位一下。",
    };

    public string CycleText
    {
        get
        {
            var interval = Math.Max(LongBreakInterval, 1);
            var positionInCycle = (CompletedFocusSessions % interval) + 1;
            return $"第 {positionInCycle} / {interval} 個番茄　·　今天已完成 {CompletedFocusSessions} 個";
        }
    }

    public string PrimaryActionText => IsRunning ? "暫停" : (Progress > 0 ? "繼續" : "開始");

    public string PrimaryActionGlyph => IsRunning ? "\uE769" : "\uE768";

    public Brush PhaseBrush => new SolidColorBrush(Phase switch
    {
        PomodoroPhase.Focus => ColorHelper.FromArgb(255, 0xE1, 0x4B, 0x3C),
        PomodoroPhase.ShortBreak => ColorHelper.FromArgb(255, 0x3F, 0xA7, 0x66),
        _ => ColorHelper.FromArgb(255, 0x2E, 0x7D, 0xD1),
    });

    #endregion

    #region Commands

    [RelayCommand]
    private void StartPause()
    {
        if (IsRunning)
        {
            Pause();
        }
        else
        {
            Start();
        }
    }

    /// <summary>Stops the clock and puts the current phase back to its full length.</summary>
    [RelayCommand]
    private void Reset()
    {
        Pause();
        ResetCurrentPhase();
    }

    /// <summary>Abandons the current phase and moves to the next one without counting it.</summary>
    [RelayCommand]
    private void Skip()
    {
        Pause();
        AdvancePhase(countFocusSession: false);
    }

    /// <summary>Clears the completed-tomato tally and returns to a fresh focus session.</summary>
    [RelayCommand]
    private void ResetCycle()
    {
        Pause();
        CompletedFocusSessions = 0;
        Phase = PomodoroPhase.Focus;
        ResetCurrentPhase();
    }

    #endregion

    private void Start()
    {
        if (_remaining <= TimeSpan.Zero)
        {
            _remaining = DurationFor(Phase);
        }

        _deadline = DateTimeOffset.Now + _remaining;
        IsRunning = true;
        _ticker.Start();
        RefreshClock();
    }

    private void Pause()
    {
        if (IsRunning)
        {
            _remaining = _deadline - DateTimeOffset.Now;
            if (_remaining < TimeSpan.Zero)
            {
                _remaining = TimeSpan.Zero;
            }
        }

        _ticker.Stop();
        IsRunning = false;
        RefreshClock();
    }

    private void OnTick(object sender, object e)
    {
        _remaining = _deadline - DateTimeOffset.Now;

        if (_remaining <= TimeSpan.Zero)
        {
            _remaining = TimeSpan.Zero;
            _ticker.Stop();
            IsRunning = false;
            CompletePhase();
            return;
        }

        RefreshClock();
    }

    private void CompletePhase()
    {
        var finished = Phase;
        AdvancePhase(countFocusSession: true);
        Announce(finished, Phase);

        var shouldAutoStart = Phase == PomodoroPhase.Focus ? AutoStartFocus : AutoStartBreaks;
        if (shouldAutoStart)
        {
            Start();
        }
    }

    private void AdvancePhase(bool countFocusSession)
    {
        if (Phase == PomodoroPhase.Focus)
        {
            if (countFocusSession)
            {
                CompletedFocusSessions++;
            }

            var interval = Math.Max(LongBreakInterval, 1);
            var dueForLongBreak = countFocusSession && CompletedFocusSessions % interval == 0;
            Phase = dueForLongBreak ? PomodoroPhase.LongBreak : PomodoroPhase.ShortBreak;
        }
        else
        {
            Phase = PomodoroPhase.Focus;
        }

        ResetCurrentPhase();
    }

    private void Announce(PomodoroPhase finished, PomodoroPhase next)
    {
        if (PlaySound)
        {
            SoundService.PlayChime();
        }

        if (!ShowNotifications)
        {
            return;
        }

        var title = finished == PomodoroPhase.Focus ? "番茄完成！" : "休息結束";
        var body = next switch
        {
            PomodoroPhase.Focus => $"開始下一個 {FocusMinutes} 分鐘的專注。",
            PomodoroPhase.ShortBreak => $"休息 {ShortBreakMinutes} 分鐘。",
            _ => $"長休息 {LongBreakMinutes} 分鐘，走遠一點。",
        };

        NotificationService.Show(title, body);
    }

    private void ResetCurrentPhase()
    {
        _remaining = DurationFor(Phase);
        RefreshClock();
    }

    private TimeSpan DurationFor(PomodoroPhase phase) => TimeSpan.FromMinutes(phase switch
    {
        PomodoroPhase.Focus => Math.Max(FocusMinutes, 1),
        PomodoroPhase.ShortBreak => Math.Max(ShortBreakMinutes, 1),
        _ => Math.Max(LongBreakMinutes, 1),
    });

    private void RefreshClock()
    {
        OnPropertyChanged(nameof(TimeText));
        OnPropertyChanged(nameof(Progress));
        OnPropertyChanged(nameof(PrimaryActionText));
    }

    partial void OnPhaseChanged(PomodoroPhase value)
    {
        OnPropertyChanged(nameof(PhaseTitle));
        OnPropertyChanged(nameof(PhaseHint));
        OnPropertyChanged(nameof(PhaseBrush));
    }

    partial void OnIsRunningChanged(bool value)
    {
        OnPropertyChanged(nameof(PrimaryActionText));
        OnPropertyChanged(nameof(PrimaryActionGlyph));
    }

    partial void OnCompletedFocusSessionsChanged(int value) => OnPropertyChanged(nameof(CycleText));
}
