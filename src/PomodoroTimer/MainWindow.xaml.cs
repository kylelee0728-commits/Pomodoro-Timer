using System.ComponentModel;
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using PomodoroTimer.ViewModels;
using Windows.Graphics;

namespace PomodoroTimer;

public sealed partial class MainWindow : Window
{
    public MainWindow()
    {
        ViewModel = new TimerViewModel();
        InitializeComponent();

        ExtendsContentIntoTitleBar = true;
        SetTitleBar(DragRegion);

        AppWindow.Resize(new SizeInt32(460, 680));
        ApplyAlwaysOnTop(ViewModel.AlwaysOnTop);

        ViewModel.PropertyChanged += OnViewModelPropertyChanged;
        Closed += (_, _) => ViewModel.PropertyChanged -= OnViewModelPropertyChanged;
    }

    public TimerViewModel ViewModel { get; }

    private void OnToggleSettings(object sender, RoutedEventArgs e)
        => Shell.IsPaneOpen = !Shell.IsPaneOpen;

    private void OnViewModelPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        if (e.PropertyName == nameof(TimerViewModel.AlwaysOnTop))
        {
            ApplyAlwaysOnTop(ViewModel.AlwaysOnTop);
        }
    }

    private void ApplyAlwaysOnTop(bool alwaysOnTop)
    {
        if (AppWindow.Presenter is OverlappedPresenter presenter)
        {
            presenter.IsAlwaysOnTop = alwaysOnTop;
        }
    }
}
