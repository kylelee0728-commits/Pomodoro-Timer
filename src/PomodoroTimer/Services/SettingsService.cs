using System.Text.Json;

namespace PomodoroTimer.Services;

/// <summary>
/// Loads and saves <see cref="PomodoroSettings"/> to %LocalAppData%\PomodoroTimer\settings.json.
/// A plain file is used (rather than ApplicationData) so the app also works unpackaged.
/// </summary>
public static class SettingsService
{
    private static readonly string Folder = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "PomodoroTimer");

    private static readonly string FilePath = Path.Combine(Folder, "settings.json");

    private static readonly JsonSerializerOptions Options = new() { WriteIndented = true };

    public static PomodoroSettings Load()
    {
        try
        {
            if (File.Exists(FilePath))
            {
                var loaded = JsonSerializer.Deserialize<PomodoroSettings>(File.ReadAllText(FilePath));
                if (loaded is not null)
                {
                    return loaded.Clamp();
                }
            }
        }
        catch (Exception)
        {
            // Corrupt or unreadable settings should never block startup.
        }

        return new PomodoroSettings();
    }

    public static void Save(PomodoroSettings settings)
    {
        try
        {
            Directory.CreateDirectory(Folder);
            File.WriteAllText(FilePath, JsonSerializer.Serialize(settings.Clamp(), Options));
        }
        catch (Exception)
        {
            // Persisting settings is best-effort.
        }
    }
}
