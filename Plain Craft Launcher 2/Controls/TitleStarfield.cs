using System.Windows;
using System.Windows.Media;

namespace PCL;

/// <summary>
/// 星空主题的静态星点装饰；仅在布局变化时重绘，不占用鼠标事件。
/// </summary>
public sealed class TitleStarfield : FrameworkElement
{
    private static readonly Brush[] StarBrushes = CreateStarBrushes();
    private static readonly Brush GlowBrush = CreateGlowBrush();

    public TitleStarfield()
    {
        IsHitTestVisible = false;
        Focusable = false;
        ClipToBounds = true;
    }

    protected override void OnRenderSizeChanged(SizeChangedInfo sizeInfo)
    {
        base.OnRenderSizeChanged(sizeInfo);
        InvalidateVisual();
    }

    protected override void OnRender(DrawingContext drawingContext)
    {
        base.OnRender(drawingContext);
        if (ActualWidth <= 0 || ActualHeight <= 0) return;

        // 固定种子和分区宽度，让改变窗口尺寸时已有星点保持位置。
        var random = new Random(7407);
        const double sectionWidth = 160;
        for (var section = 0; section < Math.Ceiling(ActualWidth / sectionWidth); section++)
        {
            for (var i = 0; i < 12; i++)
            {
                var point = new Point(section * sectionWidth + random.NextDouble() * sectionWidth,
                    3 + random.NextDouble() * Math.Max(0, ActualHeight - 6));
                var radius = 0.7 + random.NextDouble() * 1.0;
                var brush = StarBrushes[random.Next(StarBrushes.Length)];
                if (i == 0 || i == 7)
                {
                    radius *= 1.25;
                    drawingContext.DrawEllipse(GlowBrush, null, point, radius * 3.2, radius * 3.2);
                }
                drawingContext.DrawEllipse(brush, null, point, radius, radius);
            }
        }
    }

    private static Brush[] CreateStarBrushes()
    {
        return new byte[] { 50, 70, 95, 120, 150, 180 }
            .Select(alpha =>
            {
                var brush = new SolidColorBrush(Color.FromArgb(alpha, 255, 255, 255));
                brush.Freeze();
                return (Brush)brush;
            }).ToArray();
    }

    private static Brush CreateGlowBrush()
    {
        var brush = new RadialGradientBrush();
        brush.GradientStops.Add(new GradientStop(Color.FromArgb(85, 255, 255, 255), 0));
        brush.GradientStops.Add(new GradientStop(Color.FromArgb(25, 255, 255, 255), 0.4));
        brush.GradientStops.Add(new GradientStop(Colors.Transparent, 1));
        brush.Freeze();
        return brush;
    }
}
