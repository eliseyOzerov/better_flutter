import 'dart:math' as math;

import 'package:better_flutter/frame/style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

export 'style.dart';

RenderBox widgetToRenderBox(Widget widget, BuildContext context) {
  final element = widgetToElement(widget, context);
  return element.renderObject as RenderBox;
}

Element widgetToElement(Widget widget, BuildContext context) {
  final widgetKey = GlobalKey();
  final widgetWithKey = KeyedSubtree(key: widgetKey, child: widget);
  final parentElement = context as Element;
  final element = widgetWithKey.createElement();
  element.mount(parentElement, null);
  return element;
}

abstract class LayoutStrategy {
  Size performLayout(BoxConstraints constraints, LayoutModel layout, List<RenderBox> children);
}

class RowLayoutStrategy implements LayoutStrategy {
  const RowLayoutStrategy();

  /// TODO: Finish the row layout strategy
  ///
  /// What if we want to lazy load? I suppose we need to return the constrained size, but we still need to know the size of the children
  /// so we can enable the scrollable overflow widget.
  ///
  /// Actually we can store the overall size in a variable and also the start offset and more.
  ///
  /// To lazy load, I suppose we need to fill the container in terms of constraints, but I gotta check with ListView.builder
  ///
  /// Also, since we're adding separators in the Frame widget, how do we know the spacing? We can't, so it will be the implementor's responsibility
  /// to specify the spacing between each child and its separator if there are separators, or the spacing will be between children.
  @override
  Size performLayout(BoxConstraints constraints, LayoutModel layout, List<RenderBox> children) {
    if (layout.expandChildren) {
      // each child should be an equal part of the constraints (horizontal for RowLayout)
    } else if (layout.expand) {
      // return the largest constraints, position the children based on the Spread or Alignment
      // there's a problem that we don't know the number of children, so how can we divide the space?
    }

    // TODO: iterate over the children here and layout them, using the constraints, then return the size for the parent
    double newWidth = 0;
    double newHeight = 0;
    for (var child in children) {
      final parentData = child.parentData as FrameParentData;
      child.layout(constraints, parentUsesSize: true);
      final childSize = child.size;

      // Calculate the new width and height
      double newWidth = math.max(parentData.offset.dx + childSize.width, childSize.width);
      double newHeight = math.max(childSize.height, parentData.previousSibling?.size.height ?? 0);

      // Update the offset for the next child
      if (parentData.nextSibling != null) {
        (parentData.nextSibling!.parentData as FrameParentData).offset = Offset(newWidth, 0);
      }
    }

    // Return the new size
    return Size(newWidth, newHeight);
  }
}

class ColumnLayoutStrategy implements LayoutStrategy {
  @override
  Size performLayout(BoxConstraints constraints, LayoutModel layout, List<RenderBox> children) {
    return Size.zero;
    // final parentData = child.parentData as FrameParentData;
    // child.layout(BoxConstraints.tightFor(height: constraints.maxHeight), parentUsesSize: true);
    // double width = child.size.width;
    // parentData.offset += Offset(0, child.size.height);
    // return Size(math.max(width, parentData.previousSibling?.size.width ?? 0), parentData.offset.dy);
  }
}

/// It will be critical to optimize this widget for performance.
///
/// Perhaps it would be useful to have a parent Frame StatelessWidget, which will then render different RenderObjects based on the children and parameters.
/// This way we'll be able to optimize the render objects for specific use cases, but we could also have DynamicFrame, which will enable dynamic layouts at runtime.
/// By dynamic layout, I mean a layout algorithm that actually needs to animate between the render objects and not just statically layout its children.
/// We can still have dynamic layouts based on constraints for example, like for responsive designs, but they will not share paint objects between the layouts.
///
///
/// Row layout -> the next child will be placed to the right of the previous child, with a space between them
/// Column layout -> the next child will be placed below the previous child, with a space between them
/// Stack layout -> the next child will be placed above/below the previous child, according to the ZOrder, with the offset applied to it after alignment
/// Radial layout -> the next child will be placed in a circle around the previous child, with a space between them
/// Wrap layout -> the next child will be placed to the right of the previous child, with a space between them, until the width constraint is met, then the next child will be placed below the previous child, with a space between them
/// Path layout -> the next child will be placed on top of a path according to the spacing on the path
/// Grid layout -> the next child will be placed in an allotted space in the grid horizontally and vertically, with a space between them, wrapping onto the next row
/// Diagonal layout -> the next child will be placed diagonally from the previous child, with a space between them
/// Masonry layout (horizontal) -> each next child's height is equal to the previous child's height, with a space between them, similar to wrap
/// Masonry layout (vertical) -> each next child's width is equal to the previous child's width, with a space between them, similar to wrap
/// Flow layout -> the next child will be placed to the right of the previous child, with a space between them, until the width constraint is met, then the next child will be placed below the previous child, with a space between them
class Frame<T> extends StatelessWidget {
  const Frame({
    super.key,
    this.box,
    this.style,
    this.transform,
    this.layout,
    this.child,
    this.children,
    this.items,
    this.childBuilder,
    this.separator,
    this.separatorList,
    this.separatorBuilder,
  });

  final BoxModel? box;
  final Style? style;
  final Transformation? transform;
  final LayoutModel? layout;

  /// A single child to be placed inside the frame. Will be used before the children and items.
  final Widget? child;

  /// The default list of children to build this frame with. If this is not null, will be used before the items and childBuilder.
  final List<Widget>? children;

  /// The items to build this frame with.
  ///
  /// The items should be built lazily by default, so only when they're going to show up on the screen in the next pass.
  ///
  /// Reordering of items should be animated by default and the reorder animation should be something like hide the item in its current spot and show it in the new,
  /// or maybe slide the item to its new spot.
  final List<T>? items;

  /// A builder for the children. This will be used instead of the children list if not null. Give you the item and its index.
  final Widget Function(BuildContext, T, int)? childBuilder;

  /// The widget that will be placed between the children. If there's only one child, this will be ignored.
  final Widget? separator;

  /// The list of separators to be placed between the children. Will be used until the list is exhausted, then the separatorBuilder will be used if not null,
  /// or the separator will be used if not null or no separator will be added.
  final List<Widget>? separatorList;

  /// Builds a widget between the elements with the index of the current bettween element OR previous child, not including the between children in the count.
  /// Will be used instead of separator if not null.
  final Widget Function(BuildContext, int)? separatorBuilder;

  List<Widget> buildChildren(BuildContext context) {
    List<Widget> result = [];

    // Add single child if present
    if (child != null) {
      result.add(child!);
    }

    // Add children list if present
    if (children != null) {
      result.addAll(children!);
    }

    // Add items using childBuilder if both are present
    if (items != null && childBuilder != null) {
      for (int i = 0; i < items!.length; i++) {
        result.add(childBuilder!(context, items![i], i));
      }
    }

    // Add separators
    if (result.length > 1) {
      List<Widget> withSeparators = [];
      for (int i = 0; i < result.length; i++) {
        withSeparators.add(result[i]);
        if (i < result.length - 1) {
          Widget? separator;
          if (separatorList != null && i < separatorList!.length) {
            separator = separatorList![i];
          } else if (separatorBuilder != null) {
            separator = separatorBuilder!(context, i);
          } else if (this.separator != null) {
            separator = this.separator;
          }
          if (separator != null) {
            withSeparators.add(separator);
          }
        }
      }
      result = withSeparators;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    Widget child = const SizedBox(height: 100, width: 100);

    // final List<Widget> children = buildChildren(context);

    /// Insert into constrained box
    if (box != null) {
      child = ConstrainedBox(constraints: box!.buildConstraints());
    }

    // /// Setup the base widget
    // child = _RenderFrameWrapper(
    //   box: box,
    //   style: style,
    //   transform: transform,
    //   layout: layout,
    //   children: children,
    // );

    /// Add padding
    if (box?.padding != null) {
      final effectivePadding = switch ((box!.padding, style?.border?.dimensions)) {
        (null, final EdgeInsetsGeometry? padding) => padding,
        (final EdgeInsetsGeometry? padding, null) => padding,
        (_) => box!.padding!.add(style!.border!.dimensions),
      };
      child = Padding(padding: effectivePadding!, child: child);
    }

    /// Insert into StyledBox
    if (style != null) {
      child = StyledBox(style: style!, child: child);
    }

    /// Add margin
    if (box?.margin != null) {
      child = Padding(padding: box!.margin!, child: child);
    }

    /// Transform the child
    if (transform != null && !transform!.preLayout) {
      child = Transform(transform: transform!.transform!, child: child);
    }

    return child;
  }
}

/// Needs to be able to

class _RenderFrameWrapper extends MultiChildRenderObjectWidget {
  const _RenderFrameWrapper({
    this.box,
    this.style,
    this.transform,
    this.layout,
    super.children,
  });

  final BoxModel? box;
  final Style? style;
  final Transformation? transform;
  final LayoutModel? layout;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderFrame()
      ..box = box
      ..style = style
      ..transform = transform
      ..layoutModel = layout;
  }

  @override
  void updateRenderObject(BuildContext context, RenderFrame renderObject) {
    renderObject
      ..box = box
      ..style = style
      ..transform = transform
      ..layoutModel = layout;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    if (box != null) properties.add(DiagnosticsProperty<BoxModel>('box', box));
    if (style != null) properties.add(DiagnosticsProperty<Style>('style', style));
    if (transform != null) properties.add(DiagnosticsProperty<Transformation>('transform', transform));
    if (layout != null) properties.add(DiagnosticsProperty<LayoutModel>('layout', layout));
  }
}

class RenderFrame extends RenderBox with ContainerRenderObjectMixin<RenderBox, FrameParentData>, RenderBoxContainerDefaultsMixin<RenderBox, FrameParentData> {
  // ----------------------- Properties ----------------------- //

  BoxModel? _box;
  Style? _style;
  Transformation? _transform;
  LayoutModel? _layoutModel;

  BoxModel? get box => _box;
  Style? get style => _style;
  Transformation? get transform => _transform;
  LayoutModel? get layoutModel => _layoutModel;

  set box(BoxModel? value) {
    _box = value;
    markNeedsLayout();
  }

  set style(Style? value) {
    _style = value;
    markNeedsPaint();
  }

  set transform(Transformation? value) {
    _transform = value;
    markNeedsLayout();
  }

  set layoutModel(LayoutModel? value) {
    _layoutModel = value;
    markNeedsLayout();
  }

  // // ----------------------- Constraints ----------------------- //

  // @override
  // Size computeDryLayout(covariant BoxConstraints constraints) => throw UnimplementedError();

  // @override
  // double computeMaxIntrinsicHeight(double width) => throw UnimplementedError();

  // @override
  // double computeMaxIntrinsicWidth(double height) => throw UnimplementedError();

  // @override
  // double computeMinIntrinsicHeight(double width) => throw UnimplementedError();

  // @override
  // double computeMinIntrinsicWidth(double height) => throw UnimplementedError();

  // // ----------------------- Layout ----------------------- //

  // @override
  // void setupParentData(RenderBox child) {
  //   if (child.parentData is! FrameParentData) {
  //     child.parentData = FrameParentData();
  //   }
  // }

  // /// The core function where you layout the children and define the size of the render object
  // @override
  // void performLayout() => throw UnimplementedError();

  // // @override
  // // void performLayout() {
  // //   // Step 1: Apply Box Model Constraints
  // //   BoxConstraints effectiveConstraints = constraints.loosen();
  // //   if (box?.constraints != null) {
  // //     effectiveConstraints = constraints.enforce(box!.constraints!);
  // //   }

  // //   double width = box?.width ?? effectiveConstraints.maxWidth;
  // //   double height = box?.height ?? effectiveConstraints.maxHeight;

  // //   // Handle infinite constraints
  // //   if (effectiveConstraints.maxWidth.isInfinite) {
  // //     width = box?.width ?? computeMaxIntrinsicWidth(height); // Fallback to intrinsic width
  // //   }
  // //   if (effectiveConstraints.maxHeight.isInfinite) {
  // //     height = box?.height ?? computeMaxIntrinsicHeight(width); // Fallback to intrinsic height
  // //   }

  // //   size = Size(width, height);

  // //   // Layout children
  // //   List<RenderBox> children = [];
  // //   RenderBox? child = firstChild;
  // //   while (child != null) {
  // //     children.add(child);
  // //     child = (child.parentData as FrameParentData?)?.nextSibling;
  // //   }
  // //   size = layoutModel?.strategy?.performLayout(effectiveConstraints, layoutModel!, children) ?? Size.zero;
  // // }

  // // ----------------------- Paint ----------------------- //

  @override
  void paint(PaintingContext context, Offset offset) {
    /// Paint the background and everything that's not the children
    context.canvas.drawRect(Offset.zero & size, Paint()..color = Colors.red);
  }
}

class FrameParentData extends ContainerBoxParentData<RenderBox> {}

typedef LifecycleCallback = void Function(FrameLifecycleEvent);

enum FrameLifecycleEvent { enter, appearAnimationStart, visible, disappearAnimationStart, remove }

enum Order { forward, reverse }

enum Spread { packed, even, around, between }

enum ZOrder { firstAbove, firstBelow }

enum MaskBehavior { always, never, onOverflow }

class FrameData with Diagnosticable {
  final BoxModel? box;
  final Style? style;
  final Transformation? transform;
  final LayoutModel? layout;

  FrameData({
    this.box,
    this.style,
    this.transform,
    this.layout,
  });

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    if (box != null) properties.add(DiagnosticsProperty<BoxModel>('box', box));
    if (style != null) properties.add(DiagnosticsProperty<Style>('style', style));
    if (transform != null) properties.add(DiagnosticsProperty<Transformation>('transform', transform));
    if (layout != null) properties.add(DiagnosticsProperty<LayoutModel>('layout', layout));
    super.debugFillProperties(properties);
  }
}

/// Class for injecting the box model
class BoxModel with Diagnosticable {
  // ---- Constraints ---- //

  final double? width;
  final double? height;
  final double? minWidth;
  final double? maxWidth;
  final double? minHeight;
  final double? maxHeight;
  final BoxConstraints? constraints;

  // ---- Sizing ---- //
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  /// Width/Height ratio
  final double? aspectRatio;

  BoxConstraints buildConstraints() {
    BoxConstraints defaultConstraints = BoxConstraints(
      minWidth: minWidth ?? 0,
      maxWidth: maxWidth ?? double.infinity,
      minHeight: minHeight ?? 0,
      maxHeight: maxHeight ?? double.infinity,
    );
    BoxConstraints res = constraints?.enforce(defaultConstraints) ?? defaultConstraints;
    if (width != null) res = res.tighten(width: width);
    if (height != null) res = res.tighten(height: height);
    res = applyAspectRatio(res);
    return res;
  }

  BoxConstraints applyAspectRatio(BoxConstraints constraints) {
    BoxConstraints res = constraints;
    if (aspectRatio != null) {
      if (res.hasBoundedWidth && !res.hasBoundedHeight) {
        double newHeight = res.maxWidth / aspectRatio!;
        res = res.copyWith(minHeight: newHeight, maxHeight: newHeight);
      } else if (!res.hasBoundedWidth && res.hasBoundedHeight) {
        double newWidth = res.maxHeight * aspectRatio!;
        res = res.copyWith(minWidth: newWidth, maxWidth: newWidth);
      } else {
        double currentAspectRatio = res.maxWidth / res.maxHeight;
        if (currentAspectRatio > aspectRatio!) {
          double newWidth = res.maxHeight * aspectRatio!;
          res = res.copyWith(maxWidth: newWidth);
        } else if (currentAspectRatio < aspectRatio!) {
          double newHeight = res.maxWidth / aspectRatio!;
          res = res.copyWith(maxHeight: newHeight);
        }
      }
      // If both dimensions are infinite, aspect ratio is ignored
    }
    return res;
  }

  BoxModel({
    this.width,
    this.height,
    this.minWidth = 0,
    this.maxWidth = double.infinity,
    this.minHeight = 0,
    this.maxHeight = double.infinity,
    this.constraints,
    this.margin,
    this.padding,
    this.aspectRatio,
  });

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    if (width != null) properties.add(DiagnosticsProperty<double>('width', width));
    if (height != null) properties.add(DiagnosticsProperty<double>('height', height));
    if (minWidth != null) properties.add(DiagnosticsProperty<double>('minWidth', minWidth));
    if (maxWidth != null) properties.add(DiagnosticsProperty<double>('maxWidth', maxWidth));
    if (minHeight != null) properties.add(DiagnosticsProperty<double>('minHeight', minHeight));
    if (maxHeight != null) properties.add(DiagnosticsProperty<double>('maxHeight', maxHeight));
    if (constraints != null) properties.add(DiagnosticsProperty<BoxConstraints>('constraints', constraints));
    if (margin != null) properties.add(DiagnosticsProperty<EdgeInsets>('margin', margin));
    if (padding != null) properties.add(DiagnosticsProperty<EdgeInsets>('padding', padding));
    if (aspectRatio != null) properties.add(DiagnosticsProperty<double>('aspectRatio', aspectRatio));
    super.debugFillProperties(properties);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) => describeIdentity(this);
}

class Transformation with Diagnosticable {
  /// Offsets this frame in absolute pixels
  final Offset? offset;

  /// Offsets this frame as a fraction, from 0 to 1
  final Offset? fractionalOffset;

  /// If true, the fractionalOffset uses the parent's size. If false, uses this container's size.
  final bool useParentFraction;

  /// Scales the frame
  final double? scale;

  /// Rotates the frame (radians)
  final double? rotation;

  /// Transforms the frame
  final Matrix4? transform;

  /// The origin of the transform, defaults to the center
  final Alignment? transformOrigin;

  /// Transforms the gesture detection together with the frame. Defaults to true.
  final bool transformGestures;

  /// If true, the widget will be transformed before layout, meaning that the dimensions will be calculated based on the transformed size.
  final bool preLayout;

  Transformation({
    this.offset,
    this.fractionalOffset,
    this.useParentFraction = false,
    this.transformOrigin = Alignment.center,
    this.scale,
    this.rotation,
    this.transform,
    this.transformGestures = true,
    this.preLayout = false,
  });

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    if (offset != null) properties.add(DiagnosticsProperty<Offset>('offset', offset));
    if (fractionalOffset != null) properties.add(DiagnosticsProperty<Offset>('fractionalOffset', fractionalOffset));
    if (useParentFraction) properties.add(FlagProperty('useParentFraction', value: useParentFraction, ifTrue: 'uses parent fraction'));
    if (transformOrigin != null) properties.add(DiagnosticsProperty<Alignment>('transformOrigin', transformOrigin));
    if (scale != null) properties.add(DiagnosticsProperty<double>('scale', scale));
    if (rotation != null) properties.add(DiagnosticsProperty<double>('rotation', rotation));
    if (transform != null) properties.add(DiagnosticsProperty<Matrix4>('transform', transform));
    if (transformGestures) properties.add(FlagProperty('transformGestures', value: transformGestures, ifTrue: 'transforms gestures'));
    if (preLayout) properties.add(FlagProperty('preLayout', value: preLayout, ifTrue: 'pre-layouts'));
    super.debugFillProperties(properties);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) => describeIdentity(this);
}

/// Maybe could be a base class for the layouts, since these are all the properties that any layout will need, but some layouts might have more specific properties.
///
/// Potentially useful for configuring children or even injecting them from above
class LayoutModel<T> with Diagnosticable {
  /// Easily reverse items if needed
  final bool reverseItems;

  /// Controls which child will be on top of the other in case they overlap.
  final ZOrder zOrder;

  /// The spacing between each child. If the spacing is negative, they will overlap according to the ZOrder
  ///
  /// Will be halved between each element and the separator widget.
  final double spacing;

  /// How the children of this frame will be aligned in the frame.
  final Alignment alignItems;

  /// How this frame will be aligned within the parent, defaults to center
  final Alignment alignSelf;

  /// How the children will spread in this frame, defaults to packed
  final Spread spread;

  /// Will expand children to fill the frame
  /// Check how to handle child overflow, as in what if a specific child overflows its assigned space
  final bool expandChildren;

  /// Will expand self to fill the available flexible space in the parent, handled in the layout strategy
  final bool expand;

  /// The amount of flexible space to expand the child to. If this is null, the child will respect its intrinsic dimensions.
  /// If this is 0, the child should be hidden? or maybe just same as null, idk. Maybe 0 should be the default.
  /// If the total flex is equal to this one, then the child will be expanded to the remaining space.
  final double? flex;

  /// Transition builder - I want the children to be nicely animated in and out by DEFAULT.

  final LifecycleCallback? onLifecycle;

  /// The scroll controller to use for this frame.
  final ScrollController? scrollController;

  /// The scroll physics to use for this frame. Defaults to BouncingScrollPhysics, but scroll is only activated when the content is overflowing the frame.
  /// To disable the scroll, set to NeverScrollableScrollPhysics. To always allow scroll, even if the content is not overflowing, set to AlwaysScrollableScrollPhysics.
  final ScrollPhysics? scrollPhysics;

  /// The widget that will be shown at the overflowing edge if the content is overflowing the frame.
  ///
  /// If null, the overflow will be clipped.
  final Widget? overflowWidget;

  /// The shader mask to use. Defaults to null, meaning the shader will not be added to the build process.
  final ShaderMask? shaderMask;

  /// The mask could either be always applied, never applied, or only applied when the content is overflowing the frame.
  ///
  /// Defaults to always.
  final MaskBehavior maskBehavior;

  /// If true, the mask will always be present so that it can be animated.
  /// If false, the mask will not be added to the frame as needed.
  final bool lerpMask;

  // The following should be useful for testing the layouts and creating the layout from a json file
  // For example, the developer can build the layout for a device, like iPhone 15 Pro Max, then generate the animation config
  // Later on when updating the layout, they can automatically test the animation for that device.
  // LayoutConfig - support importing the layout config from a json file
  // onLayout - callback that returns the current layout config for the duration of the animation

  const LayoutModel({
    this.reverseItems = false,
    this.zOrder = ZOrder.firstAbove,
    this.spacing = 0,
    this.alignItems = Alignment.center,
    this.alignSelf = Alignment.center,
    this.spread = Spread.packed,
    this.expandChildren = false,
    this.expand = false,
    this.onLifecycle,
    this.scrollController,
    this.scrollPhysics,
    this.overflowWidget,
    this.lerpMask = true,
    this.maskBehavior = MaskBehavior.always,
    this.shaderMask,
    this.flex,
  });

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    if (reverseItems) properties.add(FlagProperty('reverseItems', value: reverseItems, ifTrue: 'reverses items'));
    properties.add(DiagnosticsProperty<ZOrder>('zOrder', zOrder));
    properties.add(DiagnosticsProperty<double>('spacing', spacing));
    properties.add(DiagnosticsProperty<Alignment>('alignment', alignItems));
    properties.add(DiagnosticsProperty<Spread>('spread', spread));
    if (expandChildren) properties.add(FlagProperty('expandChildren', value: expandChildren, ifTrue: 'expands children'));
    if (onLifecycle != null) properties.add(DiagnosticsProperty<LifecycleCallback>('onLifecycle', onLifecycle));
    if (scrollController != null) properties.add(DiagnosticsProperty<ScrollController>('scrollController', scrollController));
    if (scrollPhysics != null) properties.add(DiagnosticsProperty<ScrollPhysics>('scrollPhysics', scrollPhysics));
    if (overflowWidget != null) properties.add(DiagnosticsProperty<Widget>('overflowWidget', overflowWidget));
    super.debugFillProperties(properties);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) => describeIdentity(this);
}
