using Microsoft.Windows.AppNotifications;
using Microsoft.Windows.AppNotifications.Builder;

namespace PomodoroTimer.Services;

/// <summary>Thin wrapper over app notifications so the view model never has to care whether toasts work.</summary>
public static class NotificationService
{
    private static bool _registered;

    public static void Initialize()
    {
        try
        {
            AppNotificationManager.Default.Register();
            _registered = true;
        }
        catch (Exception)
        {
            // Unpackaged / notification-disabled environments simply get no toasts.
            _registered = false;
        }
    }

    public static void Show(string title, string message)
    {
        if (!_registered)
        {
            return;
        }

        try
        {
            var notification = new AppNotificationBuilder()
                .AddText(title)
                .AddText(message)
                .BuildNotification();

            AppNotificationManager.Default.Show(notification);
        }
        catch (Exception)
        {
            // Ignore: a missing toast must not interrupt the session.
        }
    }
}
