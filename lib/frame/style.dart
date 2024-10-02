import 'dart:math';
import 'dart:ui';

import 'package:better_extensions/flutter_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CubicBezier {
  final Offset start;
  final Offset startControl;
  final Offset endControl;
  final Offset end;

  CubicBezier({
    required this.start,
    required this.startControl,
    required this.endControl,
    required this.end,
  });

  /// As defined by the Bernstein polynomials.
  ///
  /// B(t) = (1-t)^3 * P0 + 3(1-t)^2 * t * P1 + 3(1-t) * t^2 * P2 + t^3 * P3
  ///
  /// Where P0 is the start point, P1 is the start control point, P2 is the end control point, and P3 is the end point.
  Offset pointAt(double t) {
    return Offset(
      pow(1 - t, 3) * start.dx + 3 * pow(1 - t, 2) * t * startControl.dx + 3 * (1 - t) * pow(t, 2) * endControl.dx + pow(t, 3) * end.dx,
      pow(1 - t, 3) * start.dy + 3 * pow(1 - t, 2) * t * startControl.dy + 3 * (1 - t) * pow(t, 2) * endControl.dy + pow(t, 3) * end.dy,
    );
  }

  /// Calculate the control points for a cubic Bézier curve a' such that its middle point
  /// matches the middle point of another cubic Bézier curve a. This example uses one dimension
  /// for simplicity.
  ///
  /// Given a cubic Bézier curve a with control points P0, P1, P2, P3, and another curve a'
  /// with starting points moved backwards by a vector d, the steps to calculate the control
  /// points P1' and P2' for curve a' are as follows:
  ///
  /// 1. Define the Original Control Points:
  ///    - P0, P1, P2, P3: Control points of the original cubic Bézier curve a.
  ///
  /// 2. Move Starting and Ending Points Backwards:
  ///    - Let P0' be P0 moved backwards by a vector d.
  ///    - Let P3' be P3 moved backwards by the same vector d.
  ///    - P0' = P0 - d
  ///    - P3' = P3 - d
  ///
  /// 3. Calculate the Middle Point of Curve a:
  ///    - The middle point of the original curve a at t = 0.5 is:
  ///      M_a = (1/8) * P0 + (3/8) * P1 + (3/8) * P2 + (1/8) * P3
  ///
  /// 4. Set the Middle Point of Curve a' to be M_a:
  ///    - The middle point of the new curve a' at t = 0.5 should be equal to M_a:
  ///      M_a' = (1/8) * P0' + (3/8) * P1' + (3/8) * P2' + (1/8) * P3'
  ///
  /// 5. Substitute P0' and P3':
  ///    - Substitute P0' and P3' into the equation for M_a':
  ///      M_a' = (1/8) * (P0 - d) + (3/8) * P1' + (3/8) * P2' + (1/8) * (P3 - d)
  ///      M_a' = (1/8) * P0 + (3/8) * P1' + (3/8) * P2' + (1/8) * P3 - (1/4) * d
  ///
  /// 6. Set M_a' Equal to M_a:
  ///    - Set the middle point of curve a' equal to the middle point of curve a:
  ///      (1/8) * P0 + (3/8) * P1' + (3/8) * P2' + (1/8) * P3 - (1/4) * d = (1/8) * P0 + (3/8) * P1 + (3/8) * P2 + (1/8) * P3
  ///
  /// 7. Solve for P1' and P2':
  ///    - Simplify the equation to solve for P1' and P2':
  ///      (3/8) * P1' + (3/8) * P2' - (1/4) * d = (3/8) * P1 + (3/8) * P2
  ///      3 * P1' + 3 * P2' - 2 * d = 3 * P1 + 3 * P2
  ///      P1' + P2' = P1 + P2 + (2/3) * d
  ///
  /// 8. Assume Symmetric Adjustment:
  ///    - Assume symmetric adjustment to split the adjustment equally:
  ///      P1' = P1 + (1/3) * d
  ///      P2' = P2 + (1/3) * d
  ///
  /// This ensures that the middle point of the Bézier curve a' matches the middle point of the Bézier curve a.
}

class CubicBezierRRect {
  final CubicBezier topLeft;
  final CubicBezier topRight;
  final CubicBezier bottomLeft;
  final CubicBezier bottomRight;

  late double radius;
  late double shortestSide;

  CubicBezierRRect({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  }) {
    radius = (topLeft.start.dx - topLeft.end.dx).abs(); // all the corners should have the same radius
    shortestSide = min(topRight.end.dx - topLeft.start.dx, topLeft.end.dy - bottomLeft.start.dy).abs();
  }

  factory CubicBezierRRect.fromRectAndRadius(Rect rect, double radius) {
    const double kappa = 0.5522847498; // Approximation constant for a circle
    final double maxRadius = min(rect.width, rect.height) / 2;
    radius = radius.clamp(0, maxRadius);
    // The initialization assumes circular start and end points, and symmetric control points.
    return CubicBezierRRect(
      topLeft: CubicBezier(
        start: Offset(rect.left, rect.top + radius),
        startControl: Offset(rect.left, rect.top + (1 - kappa) * radius),
        endControl: Offset(rect.left + (1 - kappa) * radius, rect.top),
        end: Offset(rect.left + radius, rect.top),
      ),
      topRight: CubicBezier(
        start: Offset(rect.right - radius, rect.top),
        startControl: Offset(rect.right - (1 - kappa) * radius, rect.top),
        endControl: Offset(rect.right, rect.top + (1 - kappa) * radius),
        end: Offset(rect.right, rect.top + radius),
      ),
      bottomRight: CubicBezier(
        start: Offset(rect.right, rect.bottom - radius),
        startControl: Offset(rect.right, rect.bottom - (1 - kappa) * radius),
        endControl: Offset(rect.right - (1 - kappa) * radius, rect.bottom),
        end: Offset(rect.right - radius, rect.bottom),
      ),
      bottomLeft: CubicBezier(
        start: Offset(rect.left + radius, rect.bottom),
        startControl: Offset(rect.left + (1 - kappa) * radius, rect.bottom),
        endControl: Offset(rect.left, rect.bottom - (1 - kappa) * radius),
        end: Offset(rect.left, rect.bottom - radius),
      ),
    );
  }

  Path get path {
    final Path path = Path();
    path.moveTo(topLeft.start.dx, topLeft.start.dy);
    path.cubicTo(topLeft.startControl.dx, topLeft.startControl.dy, topLeft.endControl.dx, topLeft.endControl.dy, topLeft.end.dx, topLeft.end.dy);
    path.lineTo(topRight.start.dx, topRight.start.dy);
    path.cubicTo(topRight.startControl.dx, topRight.startControl.dy, topRight.endControl.dx, topRight.endControl.dy, topRight.end.dx, topRight.end.dy);
    path.lineTo(bottomRight.start.dx, bottomRight.start.dy);
    path.cubicTo(bottomRight.startControl.dx, bottomRight.startControl.dy, bottomRight.endControl.dx, bottomRight.endControl.dy, bottomRight.end.dx, bottomRight.end.dy);
    path.lineTo(bottomLeft.start.dx, bottomLeft.start.dy);
    path.cubicTo(bottomLeft.startControl.dx, bottomLeft.startControl.dy, bottomLeft.endControl.dx, bottomLeft.endControl.dy, bottomLeft.end.dx, bottomLeft.end.dy);
    path.close();
    return path;
  }

  CubicBezierRRect smooth(double smoothing) {
    assert(smoothing > 0 && smoothing <= 1);
    final maxDist = min(shortestSide / 2, 2 * radius);
    final newRadius = radius + (maxDist - radius) * smoothing;
    final delta = newRadius - radius;
    final controlDelta = delta / 3;
    // top left
    return CubicBezierRRect(
      topLeft: CubicBezier(
        start: topLeft.start.translate(0, delta),
        startControl: topLeft.startControl.translate(0, -controlDelta),
        endControl: topLeft.endControl.translate(-controlDelta, 0),
        end: topLeft.end.translate(delta, 0),
      ),
      topRight: CubicBezier(
        start: topRight.start.translate(-delta, 0),
        startControl: topRight.startControl.translate(controlDelta, 0),
        endControl: topRight.endControl.translate(0, -controlDelta),
        end: topRight.end.translate(0, delta),
      ),
      bottomRight: CubicBezier(
        start: bottomRight.start.translate(0, -delta),
        startControl: bottomRight.startControl.translate(0, controlDelta),
        endControl: bottomRight.endControl.translate(controlDelta, 0),
        end: bottomRight.end.translate(-delta, 0),
      ),
      bottomLeft: CubicBezier(
        start: bottomLeft.start.translate(delta, 0),
        startControl: bottomLeft.startControl.translate(-controlDelta, 0),
        endControl: bottomLeft.endControl.translate(0, controlDelta),
        end: bottomLeft.end.translate(0, -delta),
      ),
    );
  }
}

extension BorderRadiusExtension on BorderRadius {
  BorderRadius clamp(double min, double max) {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft.x.clamp(min, max)),
      topRight: Radius.circular(topRight.x.clamp(min, max)),
      bottomLeft: Radius.circular(bottomLeft.x.clamp(min, max)),
      bottomRight: Radius.circular(bottomRight.x.clamp(min, max)),
    );
  }

  double get maxRadius => [topLeft.x, topRight.x, bottomLeft.x, bottomRight.x].max ?? 0;
}

/// TODO: Inset constraints for the border thickness

/// A style builder which takes the interaction state and returns a style for that state.
typedef StyleBuilder = Style Function(BuildContext, Offset offset, Set<WidgetState> states);

/// Class for injecting a style. I think it makes sense to separate the box model and the style.
/// This way we can reuse the style for different box models and vice versa.
/// The complete style object, takes precedence before shorthand parameters.
/// Shorthands are still allowed (as in won't crash any asserts), with lint warnings below them to notify the user they will be ignored if also present in the passed Style. This lint should be configurable to show or not.
class Style with Diagnosticable {
  /// The color of the background of this Frame
  final Color? backgroundColor;

  /// A gradient to be used as the background of this Frame
  final Gradient? backgroundGradient;

  /// A background to be placed behind the frame.
  final Widget? background;

  /// Text and icon color
  final Color? foregroundColor;

  /// The overall opacity of this widget
  final double? opacity;

  /// A border to be used as the border of this Frame.
  /// You can use a [BoxBorder], for example for a single side border, a [StyleBorder] for a more complete set of features or any other ShapeBorder.
  final ShapeBorder? border;

  /// This is useful if you're using a [BoxBorder]. If you're looking for a more complete set of features, use [StyleBorder] instead.
  final BorderRadius? borderRadius;

  /// The shadow configs to use.
  /// Shadows should follow the clipped shape, so if there's a custom clipper or corner smoothing, the shadow should be painted by using the path resolved from these parameters.
  final List<Shadow>? dropShadows;

  /// The inner shadows to use.
  /// Inner shadows should be painted on the inside of the clipped shape, so if there's a custom clipper or corner smoothing, the inner shadow should be painted by using the path resolved from these parameters.
  final List<Shadow>? innerShadows;

  /// Blurs the whole frame
  final double? layerBlur;

  /// Blurs the background of the frame only, leaving the foreground untouched
  final double? backgroundBlur;

  /// Blurs the backdrop underneath the frame. This will probably be the main use case (the frosted glass effect).
  final double? backdropBlur;

  /// The duration of the animation for any updates to the widget config and child transitions. Child animations could override this.
  final Duration? animationDuration;

  /// The curve of the animation for any updates to the widget config and child transitions. Child animations could override this.
  final Curve? curve;

  /// Disables the animations. One can also disable them by setting the animationDuration to Duration.zero, this is a bit shorter.
  final bool disableAnimations;

  Style({
    this.backgroundColor,
    this.backgroundGradient,
    this.background,
    this.foregroundColor,
    this.opacity,
    this.border,
    this.borderRadius,
    this.dropShadows,
    this.innerShadows,
    this.layerBlur,
    this.backgroundBlur,
    this.backdropBlur,
    this.animationDuration,
    this.curve,
    this.disableAnimations = false,
  });

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    if (backgroundColor != null) properties.add(ColorProperty('backgroundColor', backgroundColor));
    if (backgroundGradient != null) properties.add(DiagnosticsProperty<Gradient>('backgroundGradient', backgroundGradient));
    if (background != null) properties.add(DiagnosticsProperty<Widget>('background', background));
    if (foregroundColor != null) properties.add(ColorProperty('foregroundColor', foregroundColor));
    if (opacity != null) properties.add(DoubleProperty('opacity', opacity));
    if (border != null) properties.add(DiagnosticsProperty<ShapeBorder>('border', border));
    if (borderRadius != null) properties.add(DiagnosticsProperty<BorderRadius>('borderRadius', borderRadius));
    if (dropShadows != null) properties.add(IterableProperty<Shadow>('shadows', dropShadows));
    if (layerBlur != null) properties.add(DoubleProperty('layerBlur', layerBlur));
    if (backgroundBlur != null) properties.add(DoubleProperty('backgroundBlur', backgroundBlur));
    if (backdropBlur != null) properties.add(DoubleProperty('backdropBlur', backdropBlur));
    if (animationDuration != null) properties.add(DiagnosticsProperty<Duration>('animationDuration', animationDuration));
    if (curve != null) properties.add(DiagnosticsProperty<Curve>('curve', curve));
    if (disableAnimations) properties.add(FlagProperty('disableAnimations', value: disableAnimations, ifTrue: 'animations disabled'));
    super.debugFillProperties(properties);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) => describeIdentity(this);
}

class StyledBox extends StatelessWidget {
  const StyledBox({
    super.key,
    required this.style,
    required this.child,
  });

  final Style style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget child = this.child;
    // if (style.background != null) {
    //   Widget background = style.background!;
    //   // if (style.backgroundBlur != null) {
    //   //   background = ImageFiltered(
    //   //     imageFilter: ImageFilter.blur(
    //   //       sigmaX: style.backgroundBlur!,
    //   //       sigmaY: style.backgroundBlur!,
    //   //     ),
    //   //     child: background,
    //   //   );
    //   // }
    //   child = Stack(
    //     children: [
    //       background,
    //       // Positioned.fill(child: background),
    //       child,
    //     ],
    //   );
    // }
    return _StyledBoxRenderer(style: style, child: child);
  }
}

class _StyledBoxRenderer extends SingleChildRenderObjectWidget {
  const _StyledBoxRenderer({
    required this.style,
    super.child,
  });

  final Style style;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderStyledBox(style: style);
  }

  @override
  void updateRenderObject(BuildContext context, RenderStyledBox renderObject) {
    renderObject.style = style;
  }
}

class RenderStyledBox extends RenderProxyBox {
  RenderStyledBox({
    required Style style,
    RenderBox? child,
  })  : _style = style,
        super(child);

  Style _style;
  Style get style => _style;
  set style(Style value) {
    if (_style == value) return;
    _style = value;
    markNeedsPaint();
    markNeedsLayout();
    markNeedsCompositingBitsUpdate();
  }

  RenderBox? _background;
  RenderBox? get background => _background;
  set background(RenderBox? value) {
    if (_background == value) return;
    _background = value;
    markNeedsPaint();
    markNeedsLayout();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_style.backdropBlur != null) {
      _paintBackdropBlur(context, offset);
    }
    if (_style.dropShadows?.isNotEmpty ?? false) {
      _paintDropShadows(context, offset);
    }
    if (_style.background == null) {
      // we could potentially paint the background in the else clause, but we'd need to put it into the child
      if (_style.backgroundGradient != null) {
        _paintGradient(context, offset);
      } else if (_style.backgroundColor != null) {
        _paintBackgroundColor(context, offset);
      }
    }
    if (_style.innerShadows?.isNotEmpty ?? false) {
      _paintInnerShadows(context, offset);
    }
    if (_style.border != null) {
      _paintBorder(context, offset);
    }

    // if (_style.layerBlur != null) {
    // context.pushLayer(
    //   ImageFilterLayer(
    //       imageFilter: ImageFilter.blur(
    //     sigmaX: _style.layerBlur!,
    //     sigmaY: _style.layerBlur!,
    //   )),
    //   (context, offset) => context.paintChild(child!, offset),
    //   offset,
    // );
    // } else {
    //   context.paintChild(child!, offset);
    // }

    // if (_style.clipAll) {
    //   _applyClipping(context, offset);
    // }
  }

  void _paintBackdropBlur(PaintingContext context, Offset offset) {
    final Path clipPath = _getClipPath(offset & size);
    context.pushClipPath(
      needsCompositing,
      Offset.zero,
      Offset.zero & size,
      clipPath,
      (context, offset) {
        context.pushLayer(
          BackdropFilterLayer(
            filter: ImageFilter.blur(
              sigmaX: _style.backdropBlur!,
              sigmaY: _style.backdropBlur!,
            ),
          ),
          (context, offset) {},
          offset,
        );
      },
    );
  }

  void _paintInnerShadows(PaintingContext context, Offset offset) {
    final Rect rect = offset & size;
    final Path path = _getClipPath(rect);
    for (final Shadow shadow in _style.innerShadows!) {
      context.canvas.saveLayer(rect, Paint());
      context.canvas.drawPath(path, Paint()..color = shadow.color);
      final Rect shadowRect = rect.shift(shadow.offset);
      final Path shadowPath = _getClipPath(shadowRect);
      context.canvas.drawPath(
        shadowPath,
        shadow.toPaint()..blendMode = BlendMode.dstOut,
      );
      context.canvas.restore();
    }
  }

  void _paintDropShadows(PaintingContext context, Offset offset) {
    final Rect rect = offset & size;
    for (final Shadow shadow in _style.dropShadows!) {
      final Paint shadowPaint = shadow.toPaint();
      context.canvas.drawPath(_getClipPath(rect.shift(shadow.offset).inflate(shadow.blurRadius)), shadowPaint);
    }
  }

  void _paintBackgroundColor(PaintingContext context, Offset offset) {
    final Path path = _getClipPath(Offset.zero & size);
    final Paint backgroundPaint = Paint()..color = _style.backgroundColor!;
    context.canvas.drawPath(path.shift(offset), backgroundPaint);
  }

  void _paintGradient(PaintingContext context, Offset offset) {
    final Path path = _getClipPath(Offset.zero & size);
    final Paint gradientPaint = Paint()..shader = _style.backgroundGradient!.createShader(offset & size);
    context.canvas.drawPath(path.shift(offset), gradientPaint);
  }

  /// We can have a box border, a rounded rectangle border, or a custom path border.
  /// In the first two cases, we can smooth the corners if the corner smoothing parameter is set.
  /// We could also just have a StyledBorder with all the parameters we need tho.
  void _paintBorder(PaintingContext context, Offset offset) {
    if (_style.border == null) return;

    final Rect rect = offset & size;
    final Canvas canvas = context.canvas;

    if (_style.border is BoxBorder && _style.borderRadius != null) {
      (_style.border as BoxBorder).paint(canvas, rect, borderRadius: _style.borderRadius, textDirection: TextDirection.ltr);
    } else if (_style.border != null) {
      _style.border!.paint(canvas, rect);
    }
  }

  Path _getClipPath(Rect rect) {
    if ((_style.border is BoxBorder || _style.border == null) && _style.borderRadius != null) {
      return Path()
        ..addRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: _style.borderRadius!.topLeft,
            topRight: _style.borderRadius!.topRight,
            bottomLeft: _style.borderRadius!.bottomLeft,
            bottomRight: _style.borderRadius!.bottomRight,
          ),
        );
    } else if (_style.border is StyleBorder) {
      return (_style.border as StyleBorder).getBasePath(rect);
    } else {
      return _style.border?.getOuterPath(rect) ?? (Path()..addRect(rect));
    }
  }

  @override
  OffsetLayer updateCompositedLayer({required covariant ImageFilterLayer? oldLayer}) {
    final ImageFilterLayer layer = oldLayer ?? ImageFilterLayer();
    layer.imageFilter = ImageFilter.blur(
      sigmaX: _style.layerBlur ?? _style.backgroundBlur ?? _style.backdropBlur ?? 0.0,
      sigmaY: _style.layerBlur ?? _style.backgroundBlur ?? _style.backdropBlur ?? 0.0,
    );
    return layer;
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Style>('style', style));
  }
}

class BorderStyle {
  /// The color of the border.
  final Color? color;

  /// The width of the border.
  final double width;

  /// The corner radii.
  final BorderRadius radius;

  /// Corner smoothing in percentage from 0 to 1. It is applied only to a uniform radius, so if the radius is not equal in all corners, this will be ignored.
  final double cornerSmoothing;

  /// A custom path to be used as the border.
  final Path? path;

  /// Use BorderStyle.strokeAlignCenter for center, BorderStyle.strokeAlignInside for inside and BorderStyle.strokeAlignOutside for outside.
  final double strokeAlign;

  /// Use [dash, gap] to create a dashed border. You can have multiple values here, like [dash, gap, dash, gap], to create a pattern.
  final List<double>? dashPattern;

  /// This will paint the border using a gradient shader. You can also use the shader parameter to paint more complex shaders.
  final Gradient? gradient;

  /// This will paint the border using a custom shader. You have to set the width to the whole border shader width, otherwise it will be clipped.
  final Shader? shader;

  /// Add drop shadows to the border.
  final List<Shadow>? dropShadows;

  /// Add inner shadows to the border.
  final List<Shadow>? innerShadows;

  /// Blurs the border.
  final double? blur;

  BorderStyle({
    this.color,
    this.width = 0,
    this.radius = BorderRadius.zero,
    this.cornerSmoothing = 0,
    this.path,
    this.strokeAlign = BorderSide.strokeAlignCenter,
    this.dashPattern,
    this.gradient,
    this.shader,
    this.dropShadows,
    this.innerShadows,
    this.blur,
  });

  static BorderStyle none = BorderStyle();

  BorderStyle copyWith({
    Color? color,
    double? width,
    BorderRadius? radius,
    double? cornerSmoothing,
    Path? path,
    double? strokeAlign,
    List<double>? dashPattern,
    Gradient? gradient,
    Shader? shader,
    List<Shadow>? dropShadows,
    List<Shadow>? innerShadows,
    double? blur,
  }) {
    return BorderStyle(
      color: color ?? this.color,
      width: width ?? this.width,
      radius: radius ?? this.radius,
      cornerSmoothing: cornerSmoothing ?? this.cornerSmoothing,
      path: path ?? this.path,
      strokeAlign: strokeAlign ?? this.strokeAlign,
      dashPattern: dashPattern ?? this.dashPattern,
      gradient: gradient ?? this.gradient,
      shader: shader ?? this.shader,
      dropShadows: dropShadows ?? this.dropShadows,
      innerShadows: innerShadows ?? this.innerShadows,
      blur: blur ?? this.blur,
    );
  }
}

class StyleBorder extends ShapeBorder {
  /// The color of the border.
  final Color? color;

  /// The width of the border.
  final double width;

  /// The corner radii.
  final BorderRadius? radius;

  /// Corner smoothing in percentage from 0 to 1. It is applied only to a uniform radius, so if the radius is not equal in all corners, this will be ignored.
  /// If a path is provided, this will be ignored.
  final double cornerSmoothing;

  /// A custom path to be used as the border.
  final Path? path;

  /// Use BorderStyle.strokeAlignCenter for center, BorderStyle.strokeAlignInside for inside and BorderStyle.strokeAlignOutside for outside.
  final double strokeAlign;

  /// The stroke cap type. Defaults to round.
  final StrokeCap cap;

  /// The stroke join type. Defaults to round.
  final StrokeJoin join;

  /// Use [dash, gap] values to create a dashed border. Multiple pairs are currently not supported, but I'd like to add support for that later.
  final List<double>? dashPattern;

  /// This will paint the border using a gradient shader. You can also use the shader parameter to paint more complex shaders.
  final Gradient? gradient;

  /// This will paint the border using a custom shader. You have to set the width to the whole border shader width, otherwise it will be clipped.
  final Shader? shader;

  /// TODO: Add drop shadows to the border.
  // final List<Shadow>? dropShadows;

  /// TODO: Add inner shadows to the border.
  // final List<Shadow>? innerShadows;

  /// TODO: Add blur to the border.
  // final double? blur;

  const StyleBorder({
    this.color,
    this.width = 0,
    this.radius,
    this.cornerSmoothing = 0,
    this.path,
    this.strokeAlign = BorderSide.strokeAlignCenter,
    this.cap = StrokeCap.round,
    this.join = StrokeJoin.round,
    this.dashPattern,
    this.gradient,
    this.shader,
  });

  factory StyleBorder.fromBorderStyle(BorderStyle style) {
    return StyleBorder(
      color: style.color,
      width: style.width,
      radius: style.radius,
      cornerSmoothing: style.cornerSmoothing,
      path: style.path,
      strokeAlign: style.strokeAlign,
      dashPattern: style.dashPattern,
      gradient: style.gradient,
      shader: style.shader,
    );
  }

  StyleBorder copyWith({
    Color? color,
    double? width,
    BorderRadius? radius,
    double? cornerSmoothing,
    Path? path,
    double? strokeAlign,
    List<double>? dashPattern,
    Gradient? gradient,
    Shader? shader,
  }) {
    return StyleBorder(
      color: color ?? this.color,
      width: width ?? this.width,
      radius: radius ?? this.radius,
      cornerSmoothing: cornerSmoothing ?? this.cornerSmoothing,
      path: path ?? this.path,
      strokeAlign: strokeAlign ?? this.strokeAlign,
      dashPattern: dashPattern ?? this.dashPattern,
      gradient: gradient ?? this.gradient,
      shader: shader ?? this.shader,
    );
  }

  /// Get the amount of the stroke width that lies inside of the [BorderSide].
  ///
  /// For example, this will return the [width] for a [strokeAlign] of -1, half
  /// the [width] for a [strokeAlign] of 0, and 0 for a [strokeAlign] of 1.
  double get strokeInset => width * (1 - (1 + strokeAlign) / 2);

  /// Get the amount of the stroke width that lies outside of the [BorderSide].
  ///
  /// For example, this will return 0 for a [strokeAlign] of -1, half the
  /// [width] for a [strokeAlign] of 0, and the [width] for a [strokeAlign]
  /// of 1.
  double get strokeOutset => width * (1 + strokeAlign) / 2;

  /// The offset of the stroke, taking into account the stroke alignment.
  ///
  /// For example, this will return the negative [width] of the stroke
  /// for a [strokeAlign] of -1, 0 for a [strokeAlign] of 0, and the
  /// [width] for a [strokeAlign] of 1.
  double get strokeOffset => width * strokeAlign;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  ShapeBorder scale(double t) {
    return this;
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder? a, double t) {
    return this;
  }

  @override
  ShapeBorder lerpTo(ShapeBorder? b, double t) {
    return this;
  }

  Path _getPath(Rect rect, {double inflate = 0}) {
    if (path != null) {
      final Matrix4 matrix = Matrix4.identity()
        ..translate(rect.left, rect.top)
        ..scale(rect.width / path!.getBounds().width, rect.height / path!.getBounds().height);
      return path!.transform(matrix.storage).shift(Offset.zero);
    }
    if (radius != null) {
      if (cornerSmoothing > 0) {
        return CubicBezierRRect.fromRectAndRadius(rect.inflate(inflate), radius!.maxRadius + inflate).smooth(cornerSmoothing).path;
      } else {
        return Path()
          ..addRRect(RRect.fromRectAndCorners(
            rect.inflate(inflate),
            topLeft: radius!.topLeft,
            topRight: radius!.topRight,
            bottomLeft: radius!.bottomLeft,
            bottomRight: radius!.bottomRight,
          ));
      }
    }
    return Path()..addRect(rect);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return _getPath(rect, inflate: -strokeInset);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _getPath(rect, inflate: strokeOutset);
  }

  /// Returns the path of the border's center.
  Path getBorderCenterPath(Rect rect, {TextDirection? textDirection}) {
    return _getPath(rect, inflate: strokeOffset / 2);
  }

  Path getBasePath(Rect rect, {TextDirection? textDirection}) {
    return _getPath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (dashPattern != null) {
      paintDashedBorder(canvas, rect, textDirection: textDirection);
    } else {
      canvas.drawPath(
        getBorderCenterPath(rect, textDirection: textDirection),
        Paint()
          ..color = color ?? Colors.transparent
          ..shader = shader ?? gradient?.createShader(rect.inflate(strokeOutset))
          ..style = PaintingStyle.stroke
          ..strokeCap = cap
          ..strokeJoin = join
          ..strokeWidth = width,
      );
    }
  }

  // This function will get the closest approximate size of the dash and space
  /// It's necessary because you don't know the exact length of the path and thus
  /// you won't be able to calculate the exact number of dashes and spaces
  (double, double) getApproximateSize(double length, double dash, double space) {
    final x = ((length - space) / (dash + space)).ceil();
    final tmp = x * dash + x * space;
    final ratio = length / tmp;
    return (dash * ratio, space * ratio);
  }

  void paintDashedBorder(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final Path path = getBorderCenterPath(rect, textDirection: textDirection);
    final metrics = path.computeMetrics().toList();
    for (final metric in metrics) {
      double currentOffset = 0;
      final maxOffset = metric.length;
      final (dashSolved, spaceSolved) = getApproximateSize(metric.length, dashPattern!.first, dashPattern!.last);
      while (currentOffset < maxOffset) {
        final drawToOffset = currentOffset + dashSolved;
        final skipToOffset = drawToOffset + spaceSolved;
        final sh = shader ?? gradient?.createShader(rect.inflate(strokeOutset));
        canvas.drawPath(
          metric.extractPath(currentOffset, drawToOffset),
          Paint()
            ..color = color!
            ..shader = sh
            ..style = PaintingStyle.stroke
            ..strokeCap = cap
            ..strokeWidth = width,
        );
        currentOffset = skipToOffset;
      }
    }
  }

  @override
  bool get preferPaintInterior => false;
}
