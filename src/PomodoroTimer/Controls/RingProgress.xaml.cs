using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.Foundation;

namespace PomodoroTimer.Controls;

/// <summary>
/// A circular progress ring that sweeps clockwise from 12 o'clock.
/// WinUI's built-in ProgressRing is indeterminate-first and can't be styled this way,
/// so the arc geometry is built by hand.
/// </summary>
public sealed partial class RingProgress : UserControl
{
    public static readonly DependencyProperty ValueProperty = DependencyProperty.Register(
        nameof(Value), typeof(double), typeof(RingProgress),
        new PropertyMetadata(0d, OnVisualPropertyChanged));

    public static readonly DependencyProperty RingThicknessProperty = DependencyProperty.Register(
        nameof(RingThickness), typeof(double), typeof(RingProgress),
        new PropertyMetadata(16d, OnVisualPropertyChanged));

    public static readonly DependencyProperty TrackBrushProperty = DependencyProperty.Register(
        nameof(TrackBrush), typeof(Brush), typeof(RingProgress),
        new PropertyMetadata(null, OnVisualPropertyChanged));

    public static readonly DependencyProperty ValueBrushProperty = DependencyProperty.Register(
        nameof(ValueBrush), typeof(Brush), typeof(RingProgress),
        new PropertyMetadata(null, OnVisualPropertyChanged));

    public RingProgress()
    {
        InitializeComponent();
    }

    /// <summary>Progress from 0 to 1.</summary>
    public double Value
    {
        get => (double)GetValue(ValueProperty);
        set => SetValue(ValueProperty, value);
    }

    public double RingThickness
    {
        get => (double)GetValue(RingThicknessProperty);
        set => SetValue(RingThicknessProperty, value);
    }

    public Brush? TrackBrush
    {
        get => (Brush?)GetValue(TrackBrushProperty);
        set => SetValue(TrackBrushProperty, value);
    }

    public Brush? ValueBrush
    {
        get => (Brush?)GetValue(ValueBrushProperty);
        set => SetValue(ValueBrushProperty, value);
    }

    private static void OnVisualPropertyChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
        => ((RingProgress)d).Redraw();

    private void OnSizeChanged(object sender, SizeChangedEventArgs e) => Redraw();

    private void Redraw()
    {
        var side = Math.Min(ActualWidth, ActualHeight);
        if (side <= 0)
        {
            return;
        }

        var thickness = Math.Min(RingThickness, side / 2);
        var radius = (side - thickness) / 2;
        var centre = new Point(ActualWidth / 2, ActualHeight / 2);

        TrackPath.Stroke = TrackBrush;
        TrackPath.StrokeThickness = thickness;
        TrackPath.Data = new EllipseGeometry { Center = centre, RadiusX = radius, RadiusY = radius };

        ValuePath.Stroke = ValueBrush;
        ValuePath.StrokeThickness = thickness;

        var fraction = Math.Clamp(Value, 0, 1);
        if (fraction <= 0.0005)
        {
            ValuePath.Data = null;
            return;
        }

        if (fraction >= 0.9995)
        {
            ValuePath.Data = new EllipseGeometry { Center = centre, RadiusX = radius, RadiusY = radius };
            return;
        }

        var sweep = fraction * 2 * Math.PI;
        var figure = new PathFigure { StartPoint = PointOnCircle(centre, radius, 0) };
        figure.Segments.Add(new ArcSegment
        {
            Point = PointOnCircle(centre, radius, sweep),
            Size = new Size(radius, radius),
            SweepDirection = SweepDirection.Clockwise,
            IsLargeArc = sweep > Math.PI,
        });

        var geometry = new PathGeometry();
        geometry.Figures.Add(figure);
        ValuePath.Data = geometry;
    }

    /// <summary>Point at <paramref name="angle"/> radians clockwise from 12 o'clock.</summary>
    private static Point PointOnCircle(Point centre, double radius, double angle)
        => new(centre.X + radius * Math.Sin(angle), centre.Y - radius * Math.Cos(angle));
}
