import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
  final ShapeBorder? border;
  final BorderRadius? borderRadius;

  /// How this widget will be clipped. Could be useful to make a clipper for corner smoothing, just like in Figma.
  /// The corner smoothing should be applied as a percentage of the border radius, I guess? Not a custom path clipper like a SquircleClipper I've made already.
  final CustomClipper? clipper;

  /// Since it's also a native Figma feature, why not just add a corner smoothing parameter instead of having to add a whole ass clipper.
  /// In percentage from 0 to 1
  final double? cornerSmoothing;

  /// If true, will be applied to the whole render object. If false, only the main shape will be clipped, with the shadows still visible.
  final bool clipAll;

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
    this.clipper,
    this.cornerSmoothing,
    this.clipAll = false,
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
    if (clipper != null) properties.add(DiagnosticsProperty<CustomClipper>('clipper', clipper));
    if (cornerSmoothing != null) properties.add(DoubleProperty('cornerSmoothing', cornerSmoothing));
    if (clipAll) properties.add(FlagProperty('clipAll', value: clipAll, ifTrue: 'clips all'));
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
    if (_style.dropShadows != null && _style.dropShadows!.isNotEmpty) {
      _paintDropShadows(context, offset);
    }
    if (_style.background == null) {
      if (_style.backgroundGradient != null) {
        _paintGradient(context, offset);
      } else if (_style.backgroundColor != null) {
        _paintBackgroundColor(context, offset);
      }
    }
    if (_style.innerShadows != null && _style.innerShadows!.isNotEmpty) {
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

  void _paintBorder(PaintingContext context, Offset offset) {
    if (_style.border is BoxBorder) {
      (_style.border as BoxBorder).paint(
        context.canvas,
        offset & size,
        borderRadius: _style.borderRadius,
        textDirection: TextDirection.ltr,
      );
    } else {
      _style.border!.paint(context.canvas, offset & size);
    }
  }

  void _applyClipping(PaintingContext context, Offset offset) {
    final Path clipPath = _getClipPath(offset & size);
    context.canvas.clipPath(clipPath);
  }

  Path _getClipPath(Rect rect) {
    final path = Path();
    if (_style.border != null) {
      if (_style.border is BoxBorder && _style.borderRadius != null) {
        path.addRRect(_style.borderRadius!.toRRect(rect));
      } else {
        path.addPath(_style.border!.getOuterPath(rect), Offset.zero);
      }
    } else if (_style.borderRadius != null) {
      path.addRRect(_style.borderRadius!.toRRect(rect));
    } else {
      path.addRect(rect);
    }
    return path;
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
