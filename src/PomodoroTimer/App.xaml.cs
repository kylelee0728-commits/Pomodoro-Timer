using Microsoft.UI.Xaml;

namespace PomodoroTimer;

public partial class App : Application
{
    private Window? _window;

    public App()
    {
        InitializeComponent();
    }

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        Services.NotificationService.Initialize();

        _window = new MainWindow();
        _window.Activate();
    }
}
