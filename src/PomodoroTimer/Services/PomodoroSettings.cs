namespace PomodoroTimer.Services;

/// <summary>Durations and behaviour flags that drive the timer. Persisted as JSON.</summary>
public sealed class PomodoroSettings
{
    public int FocusMinutes { get; set; } = 25;
    public int ShortBreakMinutes { get; set; } = 5;
    public int LongBreakMinutes { get; set; } = 15;

    /// <summary>Number of focus sessions before a long break.</summary>
    public int LongBreakInterval { get; set; } = 4;

    public bool AutoStartBreaks { get; set; } = true;
    public bool AutoStartFocus { get; set; }
    public bool PlaySound { get; set; } = true;
    public bool ShowNotifications { get; set; } = true;
    public bool AlwaysOnTop { get; set; }

    public PomodoroSettings Clamp()
    {
        FocusMinutes = Math.Clamp(FocusMinutes, 1, 180);
        ShortBreakMinutes = Math.Clamp(ShortBreakMinutes, 1, 60);
        LongBreakMinutes = Math.Clamp(LongBreakMinutes, 1, 120);
        LongBreakInterval = Math.Clamp(LongBreakInterval, 1, 12);
        return this;
    }
}
