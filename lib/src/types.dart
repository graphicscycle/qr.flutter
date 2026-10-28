// ignore_for_file: public_member_api_docs

/*
 * QR.Flutter
 * Copyright (c) 2019 the QR.Flutter authors.
 * See LICENSE for distribution and usage details.
 */

import 'package:flutter/widgets.dart';
import 'dart:ui';

/// Represents a specific element / part of a QR code. This is used to isolate
/// the different parts so that we can style and modify specific parts
/// independently.
enum QrCodeElement {
  /// The 'stroke' / outer square of the QR code finder pattern element.
  finderPatternOuter,

  /// The inner/in-between square of the QR code finder pattern element.
  finderPatternInner,

  /// The "dot" square of the QR code finder pattern element.
  finderPatternDot,

  /// The individual pixels of the QR code
  codePixel,

  /// The "empty" pixels of the QR code
  codePixelEmpty,
}

/// Enumeration representing the three finder pattern (square 'eye') locations.
enum FinderPatternPosition {
  /// The top left position.
  topLeft,

  /// The top right position.
  topRight,

  /// The bottom left position.
  bottomLeft,
}

/// Enumeration representing the finder pattern eye's shape.
enum QrEyeShape {
  /// Use square eye frame.
  square,

  /// Use circular eye frame.
  circle,

  /// Rounded corner eye frame.
  roundedOuter,

  /// Circle outer, square inner
  circleOuter,

  /// Square outer, rounded inner
  roundedInner,

  /// Extra rounded
  extraRounded,

  /// Leaf shape
  leaf,

  /// Shield shape
  shield,

  /// Squircle shape
  squircle,

  /// Diamond shape
  diamond,

  /// Star shape
  star,

  /// Dots shape
  dots,

  /// Sharp corner
  sharpCorner,

  /// Asymmetric
  asymmetric,

  /// Pinched
  pinched,

  /// Square frame with a diamond center.
  diamondSquare,

  /// Open rounded arch.
  arch,

  /// Square frame with a four-point star center.
  starCut,

  /// Circle with a flat cut on the bottom-right.
  circleBite,

  /// Octagon frame and center.
  octagon,

  /// Rounded-square frame with a diamond center.
  roundedDiamond,

  /// Square frame with one large rounded corner.
  singleRound,

  /// Circle frame with a four-point sparkle.
  circleSpark,

  /// Octagon frame with a triangle center.
  octagonTriangle,

  /// Square frame with a heart center.
  squareHeart,

  /// Circle frame with a vertical capsule center.
  circlePillVertical,

  /// Circle frame with a horizontal capsule center.
  circlePillHorizontal,

  /// Octagon frame with an X center.
  octagonCross,

  /// Dotted square frame with a diagonal slash.
  dottedSlash,

  /// Circle frame with two ears.
  bear,

  /// Rounded frame with a two-by-two grid.
  windowGrid,

  /// Leaf frame with a circle center.
  leafCircle,

  /// Rounded frame with a gift icon.
  gift,

  /// Circle frame with a five-point star.
  circleStar,

  /// Basketball outline.
  basketball,

  /// Rounded frame with a play triangle.
  play,

  /// Rounded-square frame with a circle center.
  roundedCircle,

  /// Rounded frame with a paw print.
  paw,

  /// Circle frame with a split center.
  splitCircle,

  /// Multicolor dotted frame with a 3x3 center.
  dottedMatrix,

  /// Leaf frame with a jack-o'-lantern center.
  pumpkin,

  /// Offset / glitch rounded frame.
  glitch,

  /// Rounded frame with a clover center.
  clover,

  /// Gradient circle frame and pupil.
  gradientRing,

  /// Dotted rounded-square frame (asset 18).
  dottedFrame,

  /// Purple rounded frame with teal petal (asset 35).
  tealPetal,

  /// Green soft blob pupil (asset 43).
  softBlob,

  /// Circle with a curved center line (asset 46).
  ringLine,

  /// Rounded pink frame with heart pupil (asset 47).
  heartRounded,
}

/// Enumeration representing the shape of Data modules inside QR.
enum QrDataModuleShape {
  /// Use square dots.
  square,

  /// Use circular dots.
  circle,

  roundedSquare,
  diamond,
  star,
  cross,
  horizontal,
  vertical,

  /// Soft circular dots.
  roundDot,

  /// Rhombus / diamond dots.
  rhombus,

  /// Four-point sparkle dots.
  sparkle,

  /// Upward triangle dots.
  triangle,

  /// Heart-shaped dots.
  heart,

  /// Soft rounded-square dots.
  softSquare,

  /// Plus / cross dots.
  plus,

  /// Horizontal capsules that connect with neighbors.
  barHorizontal,

  /// Vertical capsules that connect with neighbors.
  barVertical,

  /// Circles with occasional heart accents.
  mixedHeart,

  /// Circles with occasional oversized blobs.
  mixedBlob,

  /// Circles with occasional butterfly accents.
  mixedButterfly,

  /// Circles with X marks and larger rounded blocks.
  mixedSpecial,

  /// Hourglass / bowtie dots.
  hourglass,
}

/// Enumeration representing the shape behind embedded picture
enum EmbeddedImageShape {
  /// Disable
  none,

  /// Use square.
  square,

  /// Use circular.
  circle,
}

/// Styling options for finder pattern eye.
@immutable
class QrEyeStyle {
  /// Create a new set of styling options for QR Eye.
  const QrEyeStyle({
    this.eyeShape = QrEyeShape.square,
    this.color,
    this.borderRadius = 0,
    this.frameColor,
    this.pupilColor,
    this.accentColor,
    this.gradient,
    this.useFigmaColors = true,
  });

  /// Eye shape.
  final QrEyeShape eyeShape;

  /// Color to tint the eye.
  final Color? color;

  /// Border radius
  final double borderRadius;

  /// Optional override for the outer eye frame color.
  final Color? frameColor;

  /// Optional override for the inner pupil color.
  final Color? pupilColor;

  /// Optional override for secondary accent details.
  final Color? accentColor;

  /// Optional gradient for themed eyes (frame + pupil).
  final Gradient? gradient;

  /// When true, decorative eyes use their Figma palette by default.
  final bool useFigmaColors;

  @override
  int get hashCode =>
      eyeShape.hashCode ^
      color.hashCode ^
      frameColor.hashCode ^
      pupilColor.hashCode ^
      accentColor.hashCode ^
      useFigmaColors.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is QrEyeStyle) {
      return eyeShape == other.eyeShape &&
          color == other.color &&
          frameColor == other.frameColor &&
          pupilColor == other.pupilColor &&
          accentColor == other.accentColor &&
          useFigmaColors == other.useFigmaColors;
    }
    return false;
  }
}

/// Styling options for data module.
@immutable
class QrDataModuleStyle {
  /// Create a new set of styling options for data modules.
  const QrDataModuleStyle({
    this.dataModuleShape = QrDataModuleShape.square,
    this.color,
    this.borderRadius = 0,
    this.roundedOutsideCorners = false,
    double? outsideBorderRadius,
  }) : _outsideBorderRadius = outsideBorderRadius;

  /// Data module shape.
  final QrDataModuleShape dataModuleShape;

  /// Color to tint the data modules.
  final Color? color;

  /// Border radius
  final double borderRadius;

  /// Only [QrDataModuleShape.square]
  /// true for rounded outside corners
  final bool roundedOutsideCorners;

  /// Only [QrDataModuleShape.square]
  /// Border radius for outside corners
  final double? _outsideBorderRadius;

  /// if [roundedOutsideCorners] == true, then by default use [borderRadius]
  /// [_outsideBorderRadius] <= [borderRadius]
  /// Get border radius for outside corners
  double get outsideBorderRadius {
    if (roundedOutsideCorners) {
      return _outsideBorderRadius != null &&
              _outsideBorderRadius! < borderRadius
          ? _outsideBorderRadius!
          : borderRadius;
    }
    return 0;
  }

  @override
  int get hashCode => dataModuleShape.hashCode ^ color.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is QrDataModuleStyle) {
      return dataModuleShape == other.dataModuleShape && color == other.color;
    }
    return false;
  }
}

/// Styling options for any embedded image overlay
@immutable
class QrEmbeddedImageStyle {
  /// Create a new set of styling options.
  const QrEmbeddedImageStyle({
    this.size,
    this.color,
    this.safeArea = false,
    this.safeAreaMultiplier = 1,
    this.embeddedImageShape = EmbeddedImageShape.none,
    this.shapeColor,
    this.borderRadius = 0,
  });

  /// The size of the image. If one dimension is zero then the other dimension
  /// will be used to scale the zero dimension based on the original image
  /// size.
  final Size? size;

  /// Color to tint the image.
  final Color? color;

  /// Hide data modules behind embedded image.
  /// Data modules are not displayed inside area
  final bool safeArea;

  /// Safe area size multiplier.
  final double safeAreaMultiplier;

  /// Shape background embedded image
  final EmbeddedImageShape embeddedImageShape;

  /// Border radius shape
  final double borderRadius;

  /// Color background
  final Color? shapeColor;

  /// Check to see if the style object has a non-null, non-zero size.
  bool get hasDefinedSize => size != null && size!.longestSide > 0;

  @override
  int get hashCode => size.hashCode ^ color.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is QrEmbeddedImageStyle) {
      return size == other.size && color == other.color;
    }
    return false;
  }
}
