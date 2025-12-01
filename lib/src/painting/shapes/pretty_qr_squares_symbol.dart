// ignore_for_file: avoid-similar-names

import 'dart:ui';

import 'package:meta/meta.dart';

import 'package:pretty_qr_code/src/rendering/pretty_qr_painting_context.dart';
import 'package:pretty_qr_code/src/rendering/pretty_qr_render_capabilities.dart';

import 'package:pretty_qr_code/src/painting/pretty_qr_brush.dart';
import 'package:pretty_qr_code/src/painting/pretty_qr_shape.dart';
import 'package:pretty_qr_code/src/painting/extensions/pretty_qr_module_extensions.dart';
import 'package:pretty_qr_code/src/painting/extensions/pretty_qr_rectangle_extensions.dart';

/// A square modules that can be rounded.
@sealed
class PrettyQrSquaresSymbol implements PrettyQrShape {
  /// The color or brush to use when filling the QR Code.
  @nonVirtual
  final Color color;

  /// Defines the ratio (`0.0`-`1.0`) how compact the modules will be.
  @nonVirtual
  final double density;

  /// The amount of rounding to be applied to the modules.
  ///
  /// This is a value between zero and one which describes how rounded the
  /// module should be. A value of zero means no rounding (sharp corners),
  /// and a value of one means that the entire module is a portion of a circle.
  final double rounding;

  /// Turns on the unified view to display `Finder Pattern`.
  @nonVirtual
  final bool unifiedFinderPattern;

  /// The thickness multiplier for the outer border of finder patterns.
  ///
  /// Default is `1.0`. Higher values make the outer border thicker.
  /// Only applies when [unifiedFinderPattern] is `true`.
  @nonVirtual
  final double finderPatternOuterThickness;

  /// The color for the outer ring of finder patterns.
  ///
  /// Default is `null` which uses the same [color] value.
  /// Only applies when [unifiedFinderPattern] is `true`.
  @nonVirtual
  final Color? finderPatternOuterColor;

  /// The size multiplier for the inner dot of finder patterns.
  ///
  /// Default is `1.0`. Lower values make the inner dot smaller.
  /// Only applies when [unifiedFinderPattern] is `true`.
  @nonVirtual
  final double finderPatternInnerDotSize;

  /// The rounding factor for the inner dot of finder patterns.
  ///
  /// Default is `null` which uses the same [rounding] value.
  /// Set to `1.0` for a circular dot, `0.0` for a square dot.
  /// Only applies when [unifiedFinderPattern] is `true`.
  @nonVirtual
  final double? finderPatternInnerRounding;

  /// Turns on the unified view to display `Alignment Patterns`.
  @nonVirtual
  final bool unifiedAlignmentPatterns;

  /// The rounding factor for the inner dot of alignment patterns.
  ///
  /// Default is `null` which uses the same [rounding] value.
  /// Set to `1.0` for a circular dot, `0.0` for a square dot.
  /// Only applies when [unifiedAlignmentPatterns] is `true`.
  @nonVirtual
  final double? alignmentPatternInnerRounding;

  /// Creates a QR Code shape in which the modules have rounded corners.
  @literal
  const PrettyQrSquaresSymbol({
    this.color = const Color(0xFF000000),
    this.density = 1,
    this.rounding = 0,
    this.unifiedFinderPattern = false,
    this.finderPatternOuterThickness = 1.0,
    this.finderPatternOuterColor,
    this.finderPatternInnerDotSize = 1.0,
    this.finderPatternInnerRounding,
    this.unifiedAlignmentPatterns = false,
    this.alignmentPatternInnerRounding,
  })  : assert(density >= 0.0 && density <= 1.0),
        assert(rounding >= 0.0 && rounding <= 1.0),
        assert(finderPatternOuterThickness > 0.0),
        assert(finderPatternInnerDotSize >= 0.0 &&
            finderPatternInnerDotSize <= 2.0),
        assert(finderPatternInnerRounding == null ||
            (finderPatternInnerRounding >= 0.0 &&
                finderPatternInnerRounding <= 1.0)),
        assert(alignmentPatternInnerRounding == null ||
            (alignmentPatternInnerRounding >= 0.0 &&
                alignmentPatternInnerRounding <= 1.0));

  @override
  void paint(PrettyQrPaintingContext context) {
    final path = Path();
    final brush = PrettyQrBrush.from(color);

    final matrix = context.matrix;
    final canvasBounds = context.estimatedBounds;
    final moduleDimension = canvasBounds.longestSide / matrix.version.dimension;

    final fillPaint = brush.toPaint(
      canvasBounds,
      textDirection: context.textDirection,
    )..style = PaintingStyle.fill;

    if (unifiedFinderPattern) {
      // Use separate color for outer ring if specified
      final outerBrush = finderPatternOuterColor != null
          ? PrettyQrBrush.from(finderPatternOuterColor!)
          : brush;
      final strokePaint = outerBrush.toPaint(
        canvasBounds,
        textDirection: context.textDirection,
      );
      strokePaint.style = PaintingStyle.stroke;
      // Apply outer thickness multiplier
      strokePaint.strokeWidth =
          (moduleDimension / 1.5) * finderPatternOuterThickness;

      // Use separate rounding for inner dot if specified
      final innerRounding = finderPatternInnerRounding ?? rounding;

      // Check if inner dot should be a perfect circle
      final isInnerDotCircular = innerRounding >= 0.95;

      // Outer ring thickness
      final ringThickness =
          (moduleDimension / 1.5) * finderPatternOuterThickness;

      // Calculate corner radius for outer ring (same for outer and inner edges = symmetric)
      // rounding 0 = sharp corners, rounding 1 = fully rounded
      final outerRingCornerRadius = moduleDimension * 3.5 * rounding;

      // Inner dot size
      final innerDotSize = moduleDimension * 3.0 * finderPatternInnerDotSize;

      // Inner dot corner radius
      final innerDotCornerRadius = moduleDimension * 1.5 * innerRounding;

      for (final pattern in matrix.positionDetectionPatterns) {
        final patternRect = pattern.resolveRect(context);
        final center = patternRect.center;

        // Draw outer ring using path (outer RRect - inner RRect)
        // Inner radius = outer radius - thickness for visually symmetric corners
        final innerRingCornerRadius =
            (outerRingCornerRadius - ringThickness).clamp(0.0, double.infinity);

        final outerRRect = RRect.fromRectAndRadius(
          patternRect,
          Radius.circular(outerRingCornerRadius),
        );
        final innerRingRRect = RRect.fromRectAndRadius(
          patternRect.deflate(ringThickness),
          Radius.circular(innerRingCornerRadius),
        );

        final ringPath = Path()
          ..addRRect(outerRRect)
          ..addRRect(innerRingRRect)
          ..fillType = PathFillType.evenOdd;

        context.canvas.drawPath(ringPath,
            fillPaint..color = outerBrush.toPaint(canvasBounds).color);

        // Reset fill paint color for inner dot
        fillPaint.color = brush.toPaint(canvasBounds).color;

        // Draw inner dot (center)
        if (isInnerDotCircular) {
          // Draw a perfect circle for the inner dot
          final circleRadius = innerDotSize / 2;
          context.canvas.drawCircle(center, circleRadius, fillPaint);
        } else {
          // Draw rounded rect for the inner dot
          final innerDotRect = Rect.fromCenter(
            center: center,
            width: innerDotSize,
            height: innerDotSize,
          );
          final innerDotRRect = RRect.fromRectAndRadius(
            innerDotRect,
            Radius.circular(innerDotCornerRadius),
          );
          context.canvas.drawRRect(innerDotRRect, fillPaint);
        }
      }
    }

    // Draw unified alignment patterns if enabled
    if (unifiedAlignmentPatterns) {
      final alignmentStrokePaint = brush.toPaint(
        canvasBounds,
        textDirection: context.textDirection,
      );
      alignmentStrokePaint.style = PaintingStyle.stroke;
      alignmentStrokePaint.strokeWidth = moduleDimension / 1.5;

      final alignmentInnerRounding = alignmentPatternInnerRounding ?? rounding;
      final isAlignmentInnerCircular = alignmentInnerRounding >= 0.95;
      final alignmentEffectiveRadius = clampDouble(rounding * 1.8, 0, 1.8);

      for (final pattern in matrix.alignmentPatterns) {
        final patternRect = pattern.resolveRect(context);
        final center = patternRect.center;

        // Draw outer border (squarish based on rounding)
        final alignmentRRect = RRect.fromRectAndRadius(
          patternRect,
          Radius.circular(moduleDimension * alignmentEffectiveRadius),
        ).deflate(moduleDimension / 3);
        context.canvas.drawRRect(alignmentRRect, alignmentStrokePaint);

        // Draw inner dot
        if (isAlignmentInnerCircular) {
          // Draw a perfect circle for the inner dot
          context.canvas.drawCircle(center, moduleDimension / 2, fillPaint);
        } else {
          final innerDotRRect = RRect.fromRectAndRadius(
            patternRect,
            Radius.circular(moduleDimension *
                clampDouble(alignmentInnerRounding * 1.4, 0, 1.4)),
          ).deflate(moduleDimension * 1.8);
          context.canvas.drawRRect(innerDotRRect, fillPaint);
        }
      }
    }

    final radius = moduleDimension / 2;
    final effectiveRadius = clampDouble(radius * rounding, 0, radius);
    final minDensity = radius < 1 ? radius * 0.1 : 1.0;
    final effectiveDensity =
        radius - clampDouble(radius * density, minDensity, radius);

    for (final module in context.matrix) {
      if (!module.isDark) continue;
      if (unifiedFinderPattern && module.isFinderPattern) continue;
      if (unifiedAlignmentPatterns && module.isAlignmentPattern) continue;

      final moduleRect = module.resolveRect(context);
      final moduleRRect = RRect.fromRectAndRadius(
        moduleRect,
        Radius.circular(effectiveRadius),
      ).deflate(effectiveDensity);

      if (PrettyQrRenderCapabilities.needsAvoidComplexPaths) {
        context.canvas.drawRRect(moduleRRect, fillPaint);
      } else {
        path.addRRect(moduleRRect);
      }
    }

    context.canvas.drawPath(path, fillPaint);
  }

  @override
  PrettyQrSquaresSymbol? lerpFrom(PrettyQrShape? a, double t) {
    if (identical(a, this)) {
      return this;
    }

    if (a == null) return this;
    if (a is! PrettyQrSquaresSymbol) return null;

    if (t == 0.0) return a;
    if (t == 1.0) return this;

    return PrettyQrSquaresSymbol(
      color: PrettyQrBrush.lerp(a.color, color, t)!,
      density: lerpDouble(a.density, density, t)!,
      rounding: lerpDouble(a.rounding, rounding, t)!,
      unifiedFinderPattern:
          t < 0.5 ? a.unifiedFinderPattern : unifiedFinderPattern,
      finderPatternOuterThickness: lerpDouble(
          a.finderPatternOuterThickness, finderPatternOuterThickness, t)!,
      finderPatternOuterColor: PrettyQrBrush.lerp(
          a.finderPatternOuterColor, finderPatternOuterColor, t),
      finderPatternInnerDotSize: lerpDouble(
          a.finderPatternInnerDotSize, finderPatternInnerDotSize, t)!,
      finderPatternInnerRounding: lerpDouble(
          a.finderPatternInnerRounding ?? a.rounding,
          finderPatternInnerRounding ?? rounding,
          t),
      unifiedAlignmentPatterns:
          t < 0.5 ? a.unifiedAlignmentPatterns : unifiedAlignmentPatterns,
      alignmentPatternInnerRounding: lerpDouble(
          a.alignmentPatternInnerRounding ?? a.rounding,
          alignmentPatternInnerRounding ?? rounding,
          t),
    );
  }

  @override
  PrettyQrSquaresSymbol? lerpTo(PrettyQrShape? b, double t) {
    if (identical(this, b)) {
      return this;
    }

    if (b == null) return this;
    if (b is! PrettyQrSquaresSymbol) return null;

    if (t == 0.0) return this;
    if (t == 1.0) return b;

    return PrettyQrSquaresSymbol(
      color: PrettyQrBrush.lerp(color, b.color, t)!,
      density: lerpDouble(density, b.density, t)!,
      rounding: lerpDouble(rounding, b.rounding, t)!,
      unifiedFinderPattern:
          t < 0.5 ? unifiedFinderPattern : b.unifiedFinderPattern,
      finderPatternOuterThickness: lerpDouble(
          finderPatternOuterThickness, b.finderPatternOuterThickness, t)!,
      finderPatternOuterColor: PrettyQrBrush.lerp(
          finderPatternOuterColor, b.finderPatternOuterColor, t),
      finderPatternInnerDotSize: lerpDouble(
          finderPatternInnerDotSize, b.finderPatternInnerDotSize, t)!,
      finderPatternInnerRounding: lerpDouble(
          finderPatternInnerRounding ?? rounding,
          b.finderPatternInnerRounding ?? b.rounding,
          t),
      unifiedAlignmentPatterns:
          t < 0.5 ? unifiedAlignmentPatterns : b.unifiedAlignmentPatterns,
      alignmentPatternInnerRounding: lerpDouble(
          alignmentPatternInnerRounding ?? rounding,
          b.alignmentPatternInnerRounding ?? b.rounding,
          t),
    );
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      color,
      density,
      rounding,
      unifiedFinderPattern,
      finderPatternOuterThickness,
      finderPatternOuterColor,
      finderPatternInnerDotSize,
      finderPatternInnerRounding,
      unifiedAlignmentPatterns,
      alignmentPatternInnerRounding,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    if (other.runtimeType != runtimeType) return false;

    return other is PrettyQrSquaresSymbol &&
        other.color == color &&
        other.density == density &&
        other.rounding == rounding &&
        other.unifiedFinderPattern == unifiedFinderPattern &&
        other.finderPatternOuterThickness == finderPatternOuterThickness &&
        other.finderPatternOuterColor == finderPatternOuterColor &&
        other.finderPatternInnerDotSize == finderPatternInnerDotSize &&
        other.finderPatternInnerRounding == finderPatternInnerRounding &&
        other.unifiedAlignmentPatterns == unifiedAlignmentPatterns &&
        other.alignmentPatternInnerRounding == alignmentPatternInnerRounding;
  }
}
