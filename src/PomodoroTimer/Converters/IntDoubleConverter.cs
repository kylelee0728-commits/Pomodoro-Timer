using Microsoft.UI.Xaml.Data;

namespace PomodoroTimer.Converters;

/// <summary>Bridges the view model's int settings to NumberBox, whose Value is a double.</summary>
public sealed class IntDoubleConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, string language)
        => value is int i ? (double)i : 0d;

    public object ConvertBack(object value, Type targetType, object parameter, string language)
    {
        if (value is double d && !double.IsNaN(d))
        {
            return (int)Math.Round(d);
        }

        // NumberBox reports NaN for an empty box; keep the previous value instead.
        return Microsoft.UI.Xaml.DependencyProperty.UnsetValue;
    }
}
