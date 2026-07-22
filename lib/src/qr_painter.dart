// ignore_for_file: unused_local_variable

/*
 * QR.Flutter
 * Copyright (c) 2019 the QR.Flutter authors.
 * See LICENSE for distribution and usage details.
 */

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr/qr.dart';
import 'dart:math' as math;
import 'errors.dart';
import 'paint_cache.dart';
import 'qr_versions.dart';
import 'types.dart';
import 'validator.dart';

// ignore_for_file: deprecated_member_use_from_same_package

const int _finderPatternLimit = 7;

// default colors for the qr code pixels
const Color _qrDefaultColor = Color(0xff000000);
const Color _qrDefaultEmptyColor = Color(0x00ffffff);

/// A [CustomPainter] object that you can use to paint a QR code.
class QrPainter extends CustomPainter {
  /// Create a new QRPainter with passed options (or defaults).
  QrPainter({
    required String data,
    required this.version,
    this.errorCorrectionLevel = QrErrorCorrectLevel.L,
    @Deprecated('use colors in eyeStyle and dataModuleStyle instead')
    this.color = _qrDefaultColor,
    @Deprecated(
      'You should use the background color value of your container widget',
    )
    this.emptyColor = _qrDefaultEmptyColor,
    this.gapless = false,
    this.embeddedImage,
    this.embeddedImageStyle = const QrEmbeddedImageStyle(),
    this.eyeStyle = const QrEyeStyle(),
    this.dataModuleStyle = const QrDataModuleStyle(),
    this.gradient,
  }) : assert(
          QrVersions.isSupportedVersion(version),
          'QR code version $version is not supported',
        ) {
    _init(data);
  }

  /// Create a new QrPainter with a pre-validated/created [QrCode] object. This
  /// constructor is useful when you have a custom validation / error handling
  /// flow or for when you need to pre-validate the QR data.
  QrPainter.withQr({
    required QrCode qr,
    @Deprecated('use colors in eyeStyle and dataModuleStyle instead')
    this.color = _qrDefaultColor,
    @Deprecated(
      'You should use the background color value of your container widget',
    )
    this.emptyColor = _qrDefaultEmptyColor,
    this.gapless = false,
    this.embeddedImage,
    this.embeddedImageStyle = const QrEmbeddedImageStyle(),
    this.eyeStyle = const QrEyeStyle(),
    this.dataModuleStyle = const QrDataModuleStyle(),
    this.gradient,
  })  : _qr = qr,
        version = qr.typeNumber,
        errorCorrectionLevel = qr.errorCorrectLevel {
    _calcVersion = version;
    _initPaints();
  }

  /// The QR code version.
  final int version; // the qr code version

  /// The error correction level of the QR code.
  final int errorCorrectionLevel; // the qr code error correction level

  /// The color of the squares.
  @Deprecated('use colors in eyeStyle and dataModuleStyle instead')
  final Color color;

  /// The gradient for all (dataModuleShape, eyeShape, embeddedImageShape)
  final Gradient? gradient;

  /// The color of the non-squares (background).
  @Deprecated(
    'You should use the background color value of your container widget',
  )
  final Color emptyColor; // the other color
  /// If set to false, the painter will leave a 1px gap between each of the
  /// squares.
  final bool gapless;

  /// The image data to embed (as an overlay) in the QR code. The image will
  /// be added to the center of the QR code.
  final ui.Image? embeddedImage;

  /// Styling options for the image overlay.
  final QrEmbeddedImageStyle embeddedImageStyle;

  /// Styling option for QR Eye ball and frame.
  final QrEyeStyle eyeStyle;

  /// Styling option for QR data module.
  final QrDataModuleStyle dataModuleStyle;

  /// The base QR code data
  QrCode? _qr;

  /// QR Image renderer
  late QrImage _qrImage;

  /// This is the version (after calculating) that we will use if the user has
  /// requested the 'auto' version.
  late final int _calcVersion;

  /// The size of the 'gap' between the pixels
  final double _gapSize = 0.25;

  /// Cache for all of the [Paint] objects.
  final PaintCache _paintCache = PaintCache();

  void _init(String data) {
    if (!QrVersions.isSupportedVersion(version)) {
      throw QrUnsupportedVersionException(version);
    }
    // configure and make the QR code data
    final validationResult = QrValidator.validate(
      data: data,
      version: version,
      errorCorrectionLevel: errorCorrectionLevel,
    );
    if (!validationResult.isValid) {
      throw validationResult.error!;
    }
    _qr = validationResult.qrCode;
    _calcVersion = _qr!.typeNumber;
    _initPaints();
  }

  void _initPaints() {
    // Initialize `QrImage` for rendering
    _qrImage = QrImage(_qr!);
    // Cache the pixel paint object. For now there is only one but we might
    // expand it to multiple later (e.g.: different colours).
    _paintCache.cache(
      Paint()..style = PaintingStyle.fill,
      QrCodeElement.codePixel,
    );
    // Cache the empty pixel paint object. Empty color is deprecated and will go
    // away.
    _paintCache.cache(
      Paint()..style = PaintingStyle.fill,
      QrCodeElement.codePixelEmpty,
    );
    // Cache the finder pattern painters. We'll keep one for each one in case
    // we want to provide customization options later.
    for (final position in FinderPatternPosition.values) {
      _paintCache.cache(
        Paint()..style = PaintingStyle.stroke,
        QrCodeElement.finderPatternOuter,
        position: position,
      );
      _paintCache.cache(
        Paint()..style = PaintingStyle.stroke,
        QrCodeElement.finderPatternInner,
        position: position,
      );
      _paintCache.cache(
        Paint()..style = PaintingStyle.fill,
        QrCodeElement.finderPatternDot,
        position: position,
      );
    }
  }

  Path _createStarPath(Rect rect) {
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final outerR = rect.width / 2;
    final innerR = outerR * 0.6;
    const points = 8;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = (i * 3.14159) / points - 3.14159 / 2;
      final x = cx + r * _cos(angle);
      final y = cy + r * _sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }

  Path _createPinchedPath(Rect rect) {
    final path = Path();
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    path.moveTo(rect.left, rect.top);
    path.quadraticBezierTo(
      cx,
      rect.top + rect.height * 0.15,
      rect.right,
      rect.top,
    );
    path.quadraticBezierTo(
      rect.right - rect.width * 0.15,
      cy,
      rect.right,
      rect.bottom,
    );
    path.quadraticBezierTo(
      cx,
      rect.bottom - rect.height * 0.15,
      rect.left,
      rect.bottom,
    );
    path.quadraticBezierTo(
      rect.left + rect.width * 0.15,
      cy,
      rect.left,
      rect.top,
    );
    return path..close();
  }

  Path _createDottedBorderPath(Rect rect, double dotSize) {
    final path = Path();
    final step = dotSize * 2;
    // top
    for (double x = rect.left; x < rect.right; x += step) {
      path.addOval(
        Rect.fromCircle(
          center: Offset(x + dotSize / 2, rect.top + dotSize / 2),
          radius: dotSize / 2,
        ),
      );
    }
    // bottom
    for (double x = rect.left; x < rect.right; x += step) {
      path.addOval(
        Rect.fromCircle(
          center: Offset(x + dotSize / 2, rect.bottom - dotSize / 2),
          radius: dotSize / 2,
        ),
      );
    }
    // left
    for (double y = rect.top + step; y < rect.bottom - step; y += step) {
      path.addOval(
        Rect.fromCircle(
          center: Offset(rect.left + dotSize / 2, y + dotSize / 2),
          radius: dotSize / 2,
        ),
      );
    }
    // right
    for (double y = rect.top + step; y < rect.bottom - step; y += step) {
      path.addOval(
        Rect.fromCircle(
          center: Offset(rect.right - dotSize / 2, y + dotSize / 2),
          radius: dotSize / 2,
        ),
      );
    }
    return path;
  }

  double _cos(double angle) {
    // Simple cos approximation using dart:math
    return math.cos(angle);
  }

  double _sin(double angle) {
    return math.sin(angle);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // if the widget has a zero size side then we cannot continue painting.
    if (size.shortestSide == 0) {
      debugPrint(
        "[QR] WARN: width or height is zero. You should set a 'size' value "
        'or nest this painter in a Widget that defines a non-zero size',
      );
      return;
    }

    final paintMetrics = _PaintMetrics(
      containerSize: size.shortestSide,
      moduleCount: _qr!.moduleCount,
      gapSize: gapless ? 0 : _gapSize,
    );

    // draw the finder pattern elements
    _drawFinderPatternItem(FinderPatternPosition.topLeft, canvas, paintMetrics);
    _drawFinderPatternItem(
      FinderPatternPosition.bottomLeft,
      canvas,
      paintMetrics,
    );
    _drawFinderPatternItem(
      FinderPatternPosition.topRight,
      canvas,
      paintMetrics,
    );

    // DEBUG: draw the inner content boundary
    //    final paint = Paint()..style = ui.PaintingStyle.stroke;
    //    paint.strokeWidth = 1;
    //    paint.color = const Color(0x55222222);
    //    canvas.drawRect(
    //        Rect.fromLTWH(paintMetrics.inset, paintMetrics.inset,
    //            paintMetrics.innerContentSize, paintMetrics.innerContentSize),
    //        paint);

    Size? embeddedImageSize;
    Offset? embeddedImagePosition;
    Offset? safeAreaPosition;
    Rect? safeAreaRect;
    if (embeddedImage != null) {
      final originalSize = Size(
        embeddedImage!.width.toDouble(),
        embeddedImage!.height.toDouble(),
      );
      final requestedSize = embeddedImageStyle.size;
      embeddedImageSize = _scaledAspectSize(size, originalSize, requestedSize);
      embeddedImagePosition = Offset(
        (size.width - embeddedImageSize.width) / 2.0,
        (size.height - embeddedImageSize.height) / 2.0,
      );
      if (embeddedImageStyle.safeArea) {
        final safeAreaMultiplier = embeddedImageStyle.safeAreaMultiplier;
        safeAreaPosition = Offset(
          (size.width - embeddedImageSize.width * safeAreaMultiplier) / 2.0,
          (size.height - embeddedImageSize.height * safeAreaMultiplier) / 2.0,
        );
        safeAreaRect = Rect.fromLTWH(
          safeAreaPosition.dx,
          safeAreaPosition.dy,
          embeddedImageSize.width * safeAreaMultiplier,
          embeddedImageSize.height * safeAreaMultiplier,
        );
      }

      if (embeddedImageStyle.embeddedImageShape != EmbeddedImageShape.none) {
        final color = _priorityColor(embeddedImageStyle.shapeColor);

        final squareRect = Rect.fromLTWH(
          embeddedImagePosition.dx,
          embeddedImagePosition.dy,
          embeddedImageSize.width,
          embeddedImageSize.height,
        );

        final paint = Paint()..color = color;

        switch (embeddedImageStyle.embeddedImageShape) {
          case EmbeddedImageShape.square:
            if (embeddedImageStyle.borderRadius > 0) {
              final roundedRect = RRect.fromRectAndRadius(
                squareRect,
                Radius.circular(embeddedImageStyle.borderRadius),
              );
              canvas.drawRRect(roundedRect, paint);
            } else {
              canvas.drawRect(squareRect, paint);
            }
            break;
          case EmbeddedImageShape.circle:
            final roundedRect = RRect.fromRectAndRadius(
              squareRect,
              Radius.circular(squareRect.width / 2),
            );
            canvas.drawRRect(roundedRect, paint);
            break;
          default:
            break;
        }
      }
    }

    final gap = !gapless ? _gapSize : 0;
    // get the painters for the pixel information
    final pixelPaint = _paintCache.firstPaint(QrCodeElement.codePixel);
    pixelPaint!.color = _priorityColor(dataModuleStyle.color);

    final emptyPixelPaint = _paintCache.firstPaint(
      QrCodeElement.codePixelEmpty,
    );
    emptyPixelPaint!.color = _qrDefaultEmptyColor;

    final borderRadius = Radius.circular(dataModuleStyle.borderRadius);
    final outsideBorderRadius = Radius.circular(
      dataModuleStyle.outsideBorderRadius,
    );
    final isRoundedOutsideCorners = dataModuleStyle.roundedOutsideCorners;

    for (var x = 0; x < _qr!.moduleCount; x++) {
      for (var y = 0; y < _qr!.moduleCount; y++) {
        // draw the finder patterns independently
        if (_isFinderPatternPosition(x, y)) {
          continue;
        }
        final isDark = _qrImage.isDark(y, x);
        final paint = isDark ? pixelPaint : emptyPixelPaint;
        if (!isDark && !isRoundedOutsideCorners) {
          continue;
        }
        // paint a pixel
        final squareRect = _createDataModuleRect(paintMetrics, x, y, gap);
        // check safeArea
        if (embeddedImageStyle.safeArea &&
            safeAreaRect?.overlaps(squareRect) == true) continue;
        switch (dataModuleStyle.dataModuleShape) {
          case QrDataModuleShape.square:
            if (dataModuleStyle.borderRadius > 0) {
              // If pixel isDark == true and outside safe area
              // than can't be rounded
              final isDarkLeft = _isDarkOnSide(
                x - 1,
                y,
                safeAreaRect,
                paintMetrics,
                gap,
              );
              final isDarkTop = _isDarkOnSide(
                x,
                y - 1,
                safeAreaRect,
                paintMetrics,
                gap,
              );
              final isDarkRight = _isDarkOnSide(
                x + 1,
                y,
                safeAreaRect,
                paintMetrics,
                gap,
              );
              final isDarkBottom = _isDarkOnSide(
                x,
                y + 1,
                safeAreaRect,
                paintMetrics,
                gap,
              );

              if (!isDark && isRoundedOutsideCorners) {
                final isDarkTopLeft = _isDarkOnSide(
                  x - 1,
                  y - 1,
                  safeAreaRect,
                  paintMetrics,
                  gap,
                );
                ;
                final isDarkTopRight = _isDarkOnSide(
                  x + 1,
                  y - 1,
                  safeAreaRect,
                  paintMetrics,
                  gap,
                );
                ;
                final isDarkBottomLeft = _isDarkOnSide(
                  x - 1,
                  y + 1,
                  safeAreaRect,
                  paintMetrics,
                  gap,
                );
                ;
                final isDarkBottomRight = _isDarkOnSide(
                  x + 1,
                  y + 1,
                  safeAreaRect,
                  paintMetrics,
                  gap,
                );
                ;

                final roundedRect = RRect.fromRectAndCorners(
                  squareRect,
                  topLeft: isDarkTop && isDarkLeft && isDarkTopLeft
                      ? outsideBorderRadius
                      : Radius.zero,
                  topRight: isDarkTop && isDarkRight && isDarkTopRight
                      ? outsideBorderRadius
                      : Radius.zero,
                  bottomLeft: isDarkBottom && isDarkLeft && isDarkBottomLeft
                      ? outsideBorderRadius
                      : Radius.zero,
                  bottomRight: isDarkBottom && isDarkRight && isDarkBottomRight
                      ? outsideBorderRadius
                      : Radius.zero,
                );
                canvas.drawPath(
                  Path.combine(
                    PathOperation.difference,
                    Path()..addRect(squareRect),
                    Path()
                      ..addRRect(roundedRect)
                      ..close(),
                  ),
                  pixelPaint,
                );
              } else {
                final roundedRect = RRect.fromRectAndCorners(
                  squareRect,
                  topLeft: isDarkTop || isDarkLeft ? Radius.zero : borderRadius,
                  topRight:
                      isDarkTop || isDarkRight ? Radius.zero : borderRadius,
                  bottomLeft:
                      isDarkBottom || isDarkLeft ? Radius.zero : borderRadius,
                  bottomRight:
                      isDarkBottom || isDarkRight ? Radius.zero : borderRadius,
                );
                canvas.drawRRect(roundedRect, paint);
              }
            } else {
              canvas.drawRect(squareRect, paint);
            }
            break;

          case QrDataModuleShape.roundedSquare:
            if (isDark) {
              final rr = RRect.fromRectAndRadius(
                  squareRect, Radius.circular(squareRect.width * 0.25));
              canvas.drawRRect(rr, paint);
            }
            break;

          case QrDataModuleShape.diamond:
            if (isDark) {
              final dp = Path()
                ..moveTo(squareRect.center.dx, squareRect.top)
                ..lineTo(squareRect.right, squareRect.center.dy)
                ..lineTo(squareRect.center.dx, squareRect.bottom)
                ..lineTo(squareRect.left, squareRect.center.dy)
                ..close();
              canvas.drawPath(dp, paint);
            }
            break;

          case QrDataModuleShape.star:
            if (isDark) {
              final sp = Path();
              final cx = squareRect.center.dx;
              final cy = squareRect.center.dy;
              final outerR = squareRect.width / 2;
              final innerR = outerR * 0.5;
              for (int i = 0; i < 8; i++) {
                final r = i.isEven ? outerR : innerR;
                final angle = (i * math.pi) / 4 - math.pi / 2;
                final x = cx + r * math.cos(angle);
                final y = cy + r * math.sin(angle);
                if (i == 0)
                  sp.moveTo(x, y);
                else
                  sp.lineTo(x, y);
              }
              sp.close();
              canvas.drawPath(sp, paint);
            }
            break;

          case QrDataModuleShape.cross:
            if (isDark) {
              final crossH = Rect.fromCenter(
                center: squareRect.center,
                width: squareRect.width,
                height: squareRect.height * 0.4,
              );
              final crossV = Rect.fromCenter(
                center: squareRect.center,
                width: squareRect.width * 0.4,
                height: squareRect.height,
              );
              canvas.drawRect(crossH, paint);
              canvas.drawRect(crossV, paint);
            }
            break;

          case QrDataModuleShape.horizontal:
            if (isDark) {
              final hr = Rect.fromCenter(
                center: squareRect.center,
                width: squareRect.width,
                height: squareRect.height * 0.5,
              );
              canvas.drawRect(hr, paint);
            }
            break;

          case QrDataModuleShape.vertical:
            if (isDark) {
              final vr = Rect.fromCenter(
                center: squareRect.center,
                width: squareRect.width * 0.5,
                height: squareRect.height,
              );
              canvas.drawRect(vr, paint);
            }
            break;

          case QrDataModuleShape.circle:
            final roundedRect = RRect.fromRectAndRadius(
              squareRect,
              Radius.circular(squareRect.width / 2),
            );
            canvas.drawRRect(roundedRect, paint);
            break;

          default:
            canvas.drawRect(squareRect, paint);
            break;
        }
      }
    }

    // set gradient for all
    if (gradient != null) {
      final paintGradient = Paint();
      paintGradient.shader = gradient!.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
      paintGradient.blendMode = BlendMode.values[12];
      canvas.drawRect(
        Rect.fromLTWH(
          paintMetrics.inset,
          paintMetrics.inset,
          paintMetrics.innerContentSize,
          paintMetrics.innerContentSize,
        ),
        paintGradient,
      );
    }

    // draw the image overlay.
    if (embeddedImage != null) {
      _drawImageOverlay(
        canvas,
        embeddedImagePosition!,
        embeddedImageSize!,
        embeddedImageStyle,
      );
    }
  }

  bool _isDarkOnSide(
    int x,
    int y,
    Rect? safeAreaRect,
    _PaintMetrics paintMetrics,
    num gap,
  ) {
    final maxIndexPixel = _qrImage.moduleCount - 1;

    final xIsContains = x >= 0 && x <= maxIndexPixel;
    final yIsContains = y >= 0 && y <= maxIndexPixel;

    return xIsContains && yIsContains
        ? _qrImage.isDark(y, x) &&
            !(safeAreaRect?.overlaps(
                  _createDataModuleRect(paintMetrics, x, y, gap),
                ) ??
                false)
        : false;
  }

  Rect _createDataModuleRect(
    _PaintMetrics paintMetrics,
    int x,
    int y,
    num gap,
  ) {
    final left = paintMetrics.inset + (x * (paintMetrics.pixelSize + gap));
    final top = paintMetrics.inset + (y * (paintMetrics.pixelSize + gap));
    var pixelHTweak = 0.0;
    var pixelVTweak = 0.0;
    if (gapless && _hasAdjacentHorizontalPixel(x, y, _qr!.moduleCount)) {
      pixelHTweak = 0.5;
    }
    if (gapless && _hasAdjacentVerticalPixel(x, y, _qr!.moduleCount)) {
      pixelVTweak = 0.5;
    }
    return Rect.fromLTWH(
      left,
      top,
      paintMetrics.pixelSize + pixelHTweak,
      paintMetrics.pixelSize + pixelVTweak,
    );
  }

  bool _hasAdjacentVerticalPixel(int x, int y, int moduleCount) {
    if (y + 1 >= moduleCount) {
      return false;
    }
    return _qrImage.isDark(y + 1, x);
  }

  bool _hasAdjacentHorizontalPixel(int x, int y, int moduleCount) {
    if (x + 1 >= moduleCount) {
      return false;
    }
    return _qrImage.isDark(y, x + 1);
  }

  bool _isFinderPatternPosition(int x, int y) {
    final isTopLeft = y < _finderPatternLimit && x < _finderPatternLimit;
    final isBottomLeft = y < _finderPatternLimit &&
        (x >= _qr!.moduleCount - _finderPatternLimit);
    final isTopRight = y >= _qr!.moduleCount - _finderPatternLimit &&
        (x < _finderPatternLimit);
    return isTopLeft || isBottomLeft || isTopRight;
  }

  void _drawFinderPatternItem(
    FinderPatternPosition position,
    Canvas canvas,
    _PaintMetrics metrics,
  ) {
    final totalGap = (_finderPatternLimit - 1) * metrics.gapSize;
    final radius = ((_finderPatternLimit * metrics.pixelSize) + totalGap) -
        metrics.pixelSize;
    final strokeAdjust = metrics.pixelSize / 2.0;
    final edgePos =
        (metrics.inset + metrics.innerContentSize) - (radius + strokeAdjust);

    Offset offset;
    if (position == FinderPatternPosition.topLeft) {
      offset = Offset(
        metrics.inset + strokeAdjust,
        metrics.inset + strokeAdjust,
      );
    } else if (position == FinderPatternPosition.bottomLeft) {
      offset = Offset(metrics.inset + strokeAdjust, edgePos);
    } else {
      offset = Offset(edgePos, metrics.inset + strokeAdjust);
    }

    // configure the paints
    final outerPaint = _paintCache.firstPaint(
      QrCodeElement.finderPatternOuter,
      position: position,
    )!;
    final color = _priorityColor(eyeStyle.color);
    outerPaint.strokeWidth = metrics.pixelSize;
    outerPaint.color = color;

    final innerPaint = _paintCache.firstPaint(
      QrCodeElement.finderPatternInner,
      position: position,
    )!;
    innerPaint.strokeWidth = metrics.pixelSize;
    innerPaint.color = emptyColor;

    final dotPaint = _paintCache.firstPaint(
      QrCodeElement.finderPatternDot,
      position: position,
    );
    dotPaint!.color = color;

    final outerRect = Rect.fromLTWH(offset.dx, offset.dy, radius, radius);

    final innerRadius = radius - (2 * metrics.pixelSize);
    final innerRect = Rect.fromLTWH(
      offset.dx + metrics.pixelSize,
      offset.dy + metrics.pixelSize,
      innerRadius,
      innerRadius,
    );

    final gap = metrics.pixelSize * 2;
    final dotSize = radius - gap - (2 * strokeAdjust);
    final dotRect = Rect.fromLTWH(
      offset.dx + metrics.pixelSize + strokeAdjust,
      offset.dy + metrics.pixelSize + strokeAdjust,
      dotSize,
      dotSize,
    );

    switch (eyeStyle.eyeShape) {
      // SVG 2 - Pure Circle
      case QrEyeShape.circle:
        final c1 = RRect.fromRectAndRadius(outerRect, Radius.circular(radius));
        canvas.drawRRect(c1, outerPaint);
        final c2 =
            RRect.fromRectAndRadius(outerRect, Radius.circular(innerRadius));
        canvas.drawRRect(c2, innerPaint);
        final c3 = RRect.fromRectAndRadius(dotRect, Radius.circular(dotSize));
        canvas.drawRRect(c3, dotPaint);
        break;

      // SVG 3 - Pure dots
      case QrEyeShape.dots:
        canvas.drawRect(outerRect, outerPaint);
        canvas.drawRect(innerRect, innerPaint);
        canvas.drawOval(dotRect, dotPaint);
        break;

      // SVG 4 - Rounded Square outer + Rounded Square dot
      case QrEyeShape.roundedOuter:
        final r4Outer =
            RRect.fromRectAndRadius(outerRect, Radius.circular(radius * 0.28));
        canvas.drawRRect(r4Outer, outerPaint);
        canvas.drawRect(innerRect, innerPaint);
        final r4Dot =
            RRect.fromRectAndRadius(dotRect, Radius.circular(dotSize * 0.28));
        canvas.drawRRect(r4Dot, dotPaint);
        break;

      // SVG 5 - Top-left sharp, rest rounded
      case QrEyeShape.squircle:
        final r8Outer = RRect.fromRectAndCorners(
          outerRect,
          topLeft: Radius.zero,
          topRight: Radius.circular(radius * 0.5),
          bottomLeft: Radius.circular(radius * 0.5),
          bottomRight: Radius.zero,
        );
        canvas.drawRRect(r8Outer, outerPaint);
        canvas.drawRect(innerRect, innerPaint);
        canvas.drawRect(dotRect, dotPaint);
        break;

      // SVG 6 - Top-left corner rounded only
      case QrEyeShape.sharpCorner:
        final path11 = Path();
        final concave = radius * 0.4;
        path11.moveTo(outerRect.left, outerRect.top);
        // top edge → top-right concave corner
        path11.lineTo(outerRect.right - concave, outerRect.top);
        path11.quadraticBezierTo(outerRect.right, outerRect.top,
            outerRect.right, outerRect.top + concave);
        // right edge → bottom-right square
        path11.lineTo(outerRect.right, outerRect.bottom);
        // bottom edge → bottom-left concave corner
        path11.lineTo(outerRect.left + concave, outerRect.bottom);
        path11.quadraticBezierTo(outerRect.left, outerRect.bottom,
            outerRect.left, outerRect.bottom - concave);
        // left edge → top-left square
        path11.lineTo(outerRect.left, outerRect.top);
        path11.close();
        canvas.drawPath(path11, outerPaint);
        canvas.drawRect(innerRect, innerPaint);

        // dot same shape
        final path11d = Path();
        final dconcave = dotSize * 0.4;
        path11d.moveTo(dotRect.left, dotRect.top);
        path11d.lineTo(dotRect.right - dconcave, dotRect.top);
        path11d.quadraticBezierTo(
            dotRect.right, dotRect.top, dotRect.right, dotRect.top + dconcave);
        path11d.lineTo(dotRect.right, dotRect.bottom);
        path11d.lineTo(dotRect.left + dconcave, dotRect.bottom);
        path11d.quadraticBezierTo(dotRect.left, dotRect.bottom, dotRect.left,
            dotRect.bottom - dconcave);
        path11d.lineTo(dotRect.left, dotRect.top);
        path11d.close();
        canvas.drawPath(path11d, dotPaint);
        break;

      // SVG 7 - Top-right corner rounded only
      case QrEyeShape.asymmetric:
        final r6Outer = RRect.fromRectAndCorners(
          outerRect,
          topLeft: Radius.circular(radius * 0.5),
          topRight: Radius.zero,
          bottomLeft: Radius.zero,
          bottomRight: Radius.zero,
        );
        canvas.drawRRect(r6Outer, outerPaint);
        canvas.drawRect(innerRect, innerPaint);
        canvas.drawRect(dotRect, dotPaint);
        break;

      // SVG 8 - top-right + bottom-left rounded
      case QrEyeShape.leaf:
        final r5Outer = RRect.fromRectAndCorners(
          outerRect,
          topLeft: Radius.circular(radius * 0.4),
          topRight: Radius.circular(radius * 0.4),
          bottomLeft: Radius.circular(radius * 0.4),
          bottomRight: Radius.zero,
        );
        canvas.drawRRect(r5Outer, outerPaint);
        canvas.drawRect(innerRect, innerPaint);

        final r5Dot = RRect.fromRectAndCorners(
          dotRect,
          topLeft: Radius.circular(dotSize * 0.4),
          topRight: Radius.circular(dotSize * 0.4),
          bottomLeft: Radius.circular(dotSize * 0.4),
          bottomRight: Radius.zero,
        );
        canvas.drawRRect(r5Dot, dotPaint);
        break;

      // SVG 9 - Pinched/inward curved
      case QrEyeShape.pinched:
        final p9 = Path();
        final bend = outerRect.width * 0.10;

        Path createPinchedPath(Rect rect, double b) {
          final path = Path();
          final cx = rect.center.dx;
          final cy = rect.center.dy;
          path.moveTo(rect.left, rect.top);
          path.quadraticBezierTo(cx, rect.top + b, rect.right, rect.top);
          path.quadraticBezierTo(rect.right - b, cy, rect.right, rect.bottom);
          path.quadraticBezierTo(cx, rect.bottom - b, rect.left, rect.bottom);
          path.quadraticBezierTo(rect.left + b, cy, rect.left, rect.top);
          path.close();
          return path;
        }

        final outerPath = createPinchedPath(outerRect, bend);
        canvas.drawPath(outerPath, outerPaint);

        final dotBend = dotRect.width * 0.10;
        final dotPath = createPinchedPath(dotRect, dotBend);
        canvas.drawPath(dotPath, dotPaint);

        break;

      // SVG 10 - Square outer + cross dot
      case QrEyeShape.extraRounded:
        canvas.drawRect(outerRect, outerPaint);
        canvas.drawRect(innerRect, innerPaint);
        final crossH = Rect.fromCenter(
          center: dotRect.center,
          width: dotRect.width,
          height: dotRect.height * 0.35,
        );
        final crossV = Rect.fromCenter(
          center: dotRect.center,
          width: dotRect.width * 0.35,
          height: dotRect.height,
        );
        canvas.drawRect(crossH, dotPaint);
        canvas.drawRect(crossV, dotPaint);
        break;

      // SVG 11 - All corners rounded
      case QrEyeShape.shield:
        final path11 = Path();
        final concaveSize = outerRect.width * 0.35;

        path11.moveTo(outerRect.left, outerRect.top);

        path11.lineTo(outerRect.right - concaveSize, outerRect.top);
        path11.quadraticBezierTo(
            outerRect.right - concaveSize,
            outerRect.top + concaveSize,
            outerRect.right,
            outerRect.top + concaveSize);

        path11.lineTo(outerRect.right, outerRect.bottom);

        path11.lineTo(outerRect.left + concaveSize, outerRect.bottom);
        path11.quadraticBezierTo(
            outerRect.left + concaveSize,
            outerRect.bottom - concaveSize,
            outerRect.left,
            outerRect.bottom - concaveSize);

        path11.close();
        canvas.drawPath(path11, outerPaint);

        final path11d = Path();
        final dConcave = dotRect.width * 0.35;

        path11d.moveTo(dotRect.left, dotRect.top);

        path11d.lineTo(dotRect.right - dConcave, dotRect.top);
        path11d.quadraticBezierTo(dotRect.right - dConcave,
            dotRect.top + dConcave, dotRect.right, dotRect.top + dConcave);

        path11d.lineTo(dotRect.right, dotRect.bottom);

        path11d.lineTo(dotRect.left + dConcave, dotRect.bottom);
        path11d.quadraticBezierTo(dotRect.left + dConcave,
            dotRect.bottom - dConcave, dotRect.left, dotRect.bottom - dConcave);

        path11d.close();
        canvas.drawPath(path11d, dotPaint);
        break;

      // SVG 12 - Dotted square border
      case QrEyeShape.star:
        final path12 = Path();

        final hCount12 = 12; // horizontal dots count
        final vCount12 = 12; // vertical dots count
        final hStep12 = outerRect.width / (hCount12 - 1);
        final vStep12 = outerRect.height / (vCount12 - 1);
        final dotR12 = metrics.pixelSize * 0.45; // dots thinner

        // top edge
        for (int i = 0; i < hCount12; i++) {
          path12.addOval(Rect.fromCircle(
              center: Offset(outerRect.left + hStep12 * i, outerRect.top),
              radius: dotR12));
        }
        // bottom edge
        for (int i = 0; i < hCount12; i++) {
          path12.addOval(Rect.fromCircle(
              center: Offset(outerRect.left + hStep12 * i, outerRect.bottom),
              radius: dotR12));
        }
        // left edge
        for (int i = 1; i < vCount12 - 1; i++) {
          path12.addOval(Rect.fromCircle(
              center: Offset(outerRect.left, outerRect.top + vStep12 * i),
              radius: dotR12));
        }
        // right edge
        for (int i = 1; i < vCount12 - 1; i++) {
          path12.addOval(Rect.fromCircle(
              center: Offset(outerRect.right, outerRect.top + vStep12 * i),
              radius: dotR12));
        }

        canvas.drawPath(path12, dotPaint);
        canvas.drawRect(innerRect, innerPaint);
        canvas.drawRect(dotRect, dotPaint);
        break;

      // SVG 13 - Dashed border
      case QrEyeShape.diamond:
        final dashW = metrics.pixelSize * 2.0; // dash width (7)
        final dashH = metrics.pixelSize * 1.4; // dash height (5)
        final gapLen = metrics.pixelSize * 1.0;
        final tiltAngle = 0.3;
        final path13 = Path();

        // tilted rectangle dash draw করার function
        void addTiltedDashes(Offset start, Offset end) {
          final dx = end.dx - start.dx;
          final dy = end.dy - start.dy;
          final len = math.sqrt(dx * dx + dy * dy);
          final nx = dx / len;
          final ny = dy / len;
          double dist = 0;
          bool draw = true;
          while (dist < len) {
            final seg = draw ? dashW : gapLen;
            final next = math.min(dist + seg, len);
            if (draw) {
              final cx = start.dx + nx * (dist + seg / 2);
              final cy = start.dy + ny * (dist + seg / 2);
              // tilted rectangle
              final angle = math.atan2(dy, dx) + tiltAngle;
              final cos = math.cos(angle);
              final sin = math.sin(angle);
              final hw = dashW / 2;
              final hh = dashH / 2;
              path13.addPolygon([
                Offset(cx + cos * hw - sin * hh, cy + sin * hw + cos * hh),
                Offset(cx - cos * hw - sin * hh, cy - sin * hw + cos * hh),
                Offset(cx - cos * hw + sin * hh, cy - sin * hw - cos * hh),
                Offset(cx + cos * hw + sin * hh, cy + sin * hw - cos * hh),
              ], true);
            }
            dist = next;
            draw = !draw;
          }
        }

        addTiltedDashes(outerRect.topLeft, outerRect.topRight);
        addTiltedDashes(outerRect.topRight, outerRect.bottomRight);
        addTiltedDashes(outerRect.bottomRight, outerRect.bottomLeft);
        addTiltedDashes(outerRect.bottomLeft, outerRect.topLeft);
        canvas.drawPath(path13, dotPaint);

        // inner = plus center + 4 sides dashes
        final centerSize = dotRect.width * 0.35;
        final centerRect = Rect.fromCenter(
          center: dotRect.center,
          width: centerSize,
          height: centerSize,
        );
        // center square
        canvas.drawRect(centerRect, dotPaint);

        // 4 sides এ tilted dashes
        final armLen = (dotRect.width - centerSize) / 2;
        final armW = metrics.pixelSize * 2.0;
        final armH = metrics.pixelSize * 1.4;

        void drawArmDash(Offset center) {
          final angle = tiltAngle;
          final cos = math.cos(angle);
          final sin = math.sin(angle);
          final hw = armW / 2;
          final hh = armH / 2;
          final armPath = Path();
          armPath.addPolygon([
            Offset(center.dx + cos * hw - sin * hh,
                center.dy + sin * hw + cos * hh),
            Offset(center.dx - cos * hw - sin * hh,
                center.dy - sin * hw + cos * hh),
            Offset(center.dx - cos * hw + sin * hh,
                center.dy - sin * hw - cos * hh),
            Offset(center.dx + cos * hw + sin * hh,
                center.dy + sin * hw - cos * hh),
          ], true);
          canvas.drawPath(armPath, dotPaint);
        }

        // top arm
        drawArmDash(Offset(dotRect.center.dx, dotRect.top + armLen / 2));
        // bottom arm
        drawArmDash(Offset(dotRect.center.dx, dotRect.bottom - armLen / 2));
        // left arm
        drawArmDash(Offset(dotRect.left + armLen / 2, dotRect.center.dy));
        // right arm
        drawArmDash(Offset(dotRect.right - armLen / 2, dotRect.center.dy));
        break;

      // SVG 14 - Parallelogram/skewed
      case QrEyeShape.circleOuter:
        final skew = outerRect.width * 0.35;
        final path14 = Path();
        // top-left = square
        path14.moveTo(outerRect.left, outerRect.top);
        // top-right = square
        path14.lineTo(outerRect.right, outerRect.top);
        // bottom-right = square
        path14.lineTo(outerRect.right, outerRect.bottom);
        // bottom-left = pointed/skewed
        path14.lineTo(outerRect.left + skew, outerRect.bottom);
        path14.lineTo(outerRect.left, outerRect.bottom - skew);
        path14.close();
        canvas.drawPath(path14, outerPaint);
        canvas.drawRect(innerRect, innerPaint);

        // dot same shape
        final dskew = dotRect.width * 0.35;
        final path14d = Path();
        path14d.moveTo(dotRect.left, dotRect.top);
        path14d.lineTo(dotRect.right, dotRect.top);
        path14d.lineTo(dotRect.right, dotRect.bottom);
        path14d.lineTo(dotRect.left + dskew, dotRect.bottom);
        path14d.lineTo(dotRect.left, dotRect.bottom - dskew);
        path14d.close();
        canvas.drawPath(path14d, dotPaint);
        break;

      // SVG 15 - Dotted circle border
      case QrEyeShape.roundedInner:
        final step1 = metrics.pixelSize * 1.2;
        final dotR1 = metrics.pixelSize * 0.5;
        final path1 = Path();

        final left = outerRect.left;
        final right = outerRect.right;
        final top = outerRect.top;
        final bottom = outerRect.bottom;
        final width = outerRect.width;
        final height = outerRect.height;

        final hCount = (width / step1).floor() + 1;
        final vCount = (height / step1).floor() + 1;
        final hStep = width / (hCount - 1);
        final vStep = height / (vCount - 1);

        // top edge
        for (int i = 0; i < hCount; i++) {
          path1.addOval(Rect.fromCircle(
              center: Offset(left + hStep * i, top), radius: dotR1));
        }
        // bottom edge
        for (int i = 0; i < hCount; i++) {
          path1.addOval(Rect.fromCircle(
              center: Offset(left + hStep * i, bottom), radius: dotR1));
        }
        // left edge
        for (int i = 1; i < vCount - 1; i++) {
          path1.addOval(Rect.fromCircle(
              center: Offset(left, top + vStep * i), radius: dotR1));
        }
        // right edge
        for (int i = 1; i < vCount - 1; i++) {
          path1.addOval(Rect.fromCircle(
              center: Offset(right, top + vStep * i), radius: dotR1));
        }

        canvas.drawPath(path1, dotPaint);

        // inner 3x3 grid circles
        final cellW = dotRect.width / 3;
        final cellH = dotRect.height / 3;
        final circR = cellW * 0.4;
        for (int row = 0; row < 3; row++) {
          for (int col = 0; col < 3; col++) {
            final cx = dotRect.left + cellW * col + cellW / 2;
            final cy = dotRect.top + cellH * row + cellH / 2;
            canvas.drawCircle(Offset(cx, cy), circR, dotPaint);
          }
        }
        break;

      // SVG 1 - Dotted square border + 9 circle dots inside
      case QrEyeShape.square:
        canvas.drawRect(outerRect, outerPaint);
        canvas.drawRect(innerRect, innerPaint);
        canvas.drawRect(dotRect, dotPaint);
        break;

      default:
        canvas.drawRect(outerRect, outerPaint);
        canvas.drawRect(innerRect, innerPaint);
        canvas.drawRect(dotRect, dotPaint);
        break;
    }
  }

  bool _hasOneNonZeroSide(Size size) => size.longestSide > 0;

  Size _scaledAspectSize(
    Size widgetSize,
    Size originalSize,
    Size? requestedSize,
  ) {
    if (requestedSize != null && !requestedSize.isEmpty) {
      return requestedSize;
    } else if (requestedSize != null && _hasOneNonZeroSide(requestedSize)) {
      final maxSide = requestedSize.longestSide;
      final ratio = maxSide / originalSize.longestSide;
      return Size(ratio * originalSize.width, ratio * originalSize.height);
    } else {
      final maxSide = 0.25 * widgetSize.shortestSide;
      final ratio = maxSide / originalSize.longestSide;
      return Size(ratio * originalSize.width, ratio * originalSize.height);
    }
  }

  void _drawImageOverlay(
    Canvas canvas,
    Offset position,
    Size size,
    QrEmbeddedImageStyle? style,
  ) {
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;
    if (style != null) {
      if (style.color != null) {
        paint.colorFilter = ColorFilter.mode(style.color!, BlendMode.srcATop);
      }
    }
    final srcSize = Size(
      embeddedImage!.width.toDouble(),
      embeddedImage!.height.toDouble(),
    );
    final src = Alignment.center.inscribe(srcSize, Offset.zero & srcSize);
    final dst = Alignment.center.inscribe(size, position & size);
    canvas.drawImageRect(embeddedImage!, src, dst, paint);
  }

  /// if [gradient] != null, then only black [_qrDefaultColor],
  /// needed for gradient
  /// else [color] or [QrPainter.color]
  Color _priorityColor(Color? color) =>
      gradient != null ? _qrDefaultColor : color ?? this.color;

  @override
  bool shouldRepaint(CustomPainter oldPainter) {
    if (oldPainter is QrPainter) {
      return errorCorrectionLevel != oldPainter.errorCorrectionLevel ||
          _calcVersion != oldPainter._calcVersion ||
          _qr != oldPainter._qr ||
          gapless != oldPainter.gapless ||
          embeddedImage != oldPainter.embeddedImage ||
          embeddedImageStyle != oldPainter.embeddedImageStyle ||
          eyeStyle != oldPainter.eyeStyle ||
          dataModuleStyle != oldPainter.dataModuleStyle;
    }
    return true;
  }

  /// Returns a [ui.Picture] object containing the QR code data.
  ui.Picture toPicture(double size) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    paint(canvas, Size(size, size));
    return recorder.endRecording();
  }

  /// Returns the raw QR code [ui.Image] object.
  Future<ui.Image> toImage(double size) {
    return toPicture(size).toImage(size.toInt(), size.toInt());
  }

  /// Returns the raw QR code image byte data.
  Future<ByteData?> toImageData(
    double size, {
    ui.ImageByteFormat format = ui.ImageByteFormat.png,
  }) async {
    final image = await toImage(size);
    return image.toByteData(format: format);
  }
}

class _PaintMetrics {
  _PaintMetrics({
    required this.containerSize,
    required this.gapSize,
    required this.moduleCount,
  }) {
    _calculateMetrics();
  }

  final int moduleCount;
  final double containerSize;
  final double gapSize;

  late final double _pixelSize;
  double get pixelSize => _pixelSize;

  late final double _innerContentSize;
  double get innerContentSize => _innerContentSize;

  late final double _inset;
  double get inset => _inset;

  void _calculateMetrics() {
    final gapTotal = (moduleCount - 1) * gapSize;
    final pixelSize = (containerSize - gapTotal) / moduleCount;
    _pixelSize = (pixelSize * 2).roundToDouble() / 2;
    _innerContentSize = (_pixelSize * moduleCount) + gapTotal;
    _inset = (containerSize - _innerContentSize) / 2;
  }
}
