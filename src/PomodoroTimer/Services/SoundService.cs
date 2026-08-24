using Microsoft.UI.Xaml;

namespace PomodoroTimer.Services;

/// <summary>
/// Plays the end-of-phase chime. WinUI's element sounds are used because they need no
/// bundled audio asset and respect the user's system sound settings.
/// </summary>
public static class SoundService
{
    public static void PlayChime()
    {
        try
        {
            ElementSoundPlayer.State = ElementSoundPlayerState.On;
            ElementSoundPlayer.Play(ElementSoundKind.Invoke);
        }
        catch (Exception)
        {
            // Audio is a nicety; never let it surface as an error.
        }
    }
}
