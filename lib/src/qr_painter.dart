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
import 'asset_shapes.dart';
import 'errors.dart';
import 'paint_cache.dart';
import 'qr_versions.dart';
import 'types.dart';
import 'validator.dart';

int? _eyeAssetId(QrEyeShape shape) {
  switch (shape) {
    case QrEyeShape.diamondSquare:
      return 16;
    case QrEyeShape.arch:
      return 17;
    case QrEyeShape.dottedFrame:
      return 18;
    case QrEyeShape.starCut:
      return 19;
    case QrEyeShape.circleBite:
      return 20;
    case QrEyeShape.octagon:
      return 21;
    case QrEyeShape.roundedDiamond:
      return 22;
    case QrEyeShape.singleRound:
      return 23;
    case QrEyeShape.circleSpark:
      return 24;
    case QrEyeShape.octagonTriangle:
      return 25;
    case QrEyeShape.squareHeart:
      return 26;
    case QrEyeShape.circlePillVertical:
      return 27;
    case QrEyeShape.circlePillHorizontal:
      return 28;
    case QrEyeShape.octagonCross:
      return 29;
    case QrEyeShape.dottedSlash:
      return 30;
    case QrEyeShape.bear:
      return 31;
    case QrEyeShape.roundedCircle:
      return 32;
    case QrEyeShape.dottedMatrix:
      return 33;
    case QrEyeShape.pumpkin:
      return 34;
    case QrEyeShape.tealPetal:
      return 35;
    case QrEyeShape.windowGrid:
      return 36;
    case QrEyeShape.glitch:
      return 37;
    case QrEyeShape.leafCircle:
      return 38;
    case QrEyeShape.gift:
      return 39;
    case QrEyeShape.circleStar:
      return 40;
    case QrEyeShape.basketball:
      return 41;
    case QrEyeShape.play:
      return 42;
    case QrEyeShape.softBlob:
      return 43;
    case QrEyeShape.splitCircle:
      return 44;
    case QrEyeShape.paw:
      return 45;
    case QrEyeShape.ringLine:
      return 46;
    case QrEyeShape.heartRounded:
      return 47;
    case QrEyeShape.clover:
      return 48;
    case QrEyeShape.gradientRing:
      return 49;
    default:
      return null;
  }
}

int? _dotAssetId(QrDataModuleShape shape) {
  switch (shape) {
    case QrDataModuleShape.square:
      return 1;
    case QrDataModuleShape.circle:
      return 2;
    case QrDataModuleShape.roundedSquare:
      return 3;
    case QrDataModuleShape.diamond:
      return 4;
    case QrDataModuleShape.star:
      return 5;
    case QrDataModuleShape.cross:
      return 6;
    case QrDataModuleShape.horizontal:
      return 7;
    case QrDataModuleShape.vertical:
      return 8;
    case QrDataModuleShape.roundDot:
      return 9;
    case QrDataModuleShape.rhombus:
      return 10;
    case QrDataModuleShape.sparkle:
      return 11;
    case QrDataModuleShape.triangle:
      return 12;
    case QrDataModuleShape.heart:
      return 13;
    case QrDataModuleShape.softSquare:
      return 14;
    case QrDataModuleShape.plus:
      return 15;
    case QrDataModuleShape.barHorizontal:
      return 16;
    case QrDataModuleShape.barVertical:
      return 17;
    case QrDataModuleShape.mixedHeart:
      return 18;
    case QrDataModuleShape.mixedBlob:
      return 19;
    case QrDataModuleShape.mixedButterfly:
      return 20;
    case QrDataModuleShape.mixedSpecial:
      return 21;
    case QrDataModuleShape.hourglass:
      return 22;
  }
}

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

  Path _regularPolygon(
    Rect rect,
    int sides, {
    double rotation = -math.pi / 2,
  }) {
    final path = Path();
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final rx = rect.width / 2;
    final ry = rect.height / 2;
    for (var i = 0; i < sides; i++) {
      final angle = rotation + (2 * math.pi * i / sides);
      final x = cx + rx * math.cos(angle);
      final y = cy + ry * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }

  Path _starPolygon(
    Rect rect,
    int points, {
    double innerRatio = 0.4,
    double rotation = -math.pi / 2,
  }) {
    final path = Path();
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final rx = rect.width / 2;
    final ry = rect.height / 2;
    final steps = points * 2;
    for (var i = 0; i < steps; i++) {
      final ratio = i.isEven ? 1.0 : innerRatio;
      final angle = rotation + (math.pi * i / points);
      final x = cx + rx * ratio * math.cos(angle);
      final y = cy + ry * ratio * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }

  Path _fourPointStar(Rect rect, {double pull = 0.18}) {
    final path = Path();
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final px = rect.width * pull;
    final py = rect.height * pull;
    path.moveTo(cx, rect.top);
    path.quadraticBezierTo(cx + px, cy - py, rect.right, cy);
    path.quadraticBezierTo(cx + px, cy + py, cx, rect.bottom);
    path.quadraticBezierTo(cx - px, cy + py, rect.left, cy);
    path.quadraticBezierTo(cx - px, cy - py, cx, rect.top);
    return path..close();
  }

  Path _heartPath(Rect rect) {
    final path = Path();
    final w = rect.width;
    final h = rect.height;
    path.addOval(
      Rect.fromLTWH(rect.left, rect.top + h * 0.02, w * 0.58, h * 0.55),
    );
    path.addOval(
      Rect.fromLTWH(
        rect.left + w * 0.42,
        rect.top + h * 0.02,
        w * 0.58,
        h * 0.55,
      ),
    );
    path.moveTo(rect.left + w * 0.06, rect.top + h * 0.36);
    path.lineTo(rect.center.dx, rect.bottom);
    path.lineTo(rect.right - w * 0.06, rect.top + h * 0.36);
    path.close();
    return path;
  }

  Path _trianglePath(Rect rect) {
    return Path()
      ..moveTo(rect.center.dx, rect.top)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
  }

  Path _plusPath(Rect rect) {
    final w = rect.width;
    final h = rect.height;
    final arm = w * 0.34;
    final path = Path();
    path.addRect(
      Rect.fromCenter(
        center: rect.center,
        width: w,
        height: arm,
      ),
    );
    path.addRect(
      Rect.fromCenter(
        center: rect.center,
        width: arm,
        height: h,
      ),
    );
    return path;
  }

  Path _sparkleDotPath(Rect rect) {
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final ix = rect.width * 0.14;
    final iy = rect.height * 0.14;
    return Path()
      ..moveTo(cx, rect.top)
      ..lineTo(cx + ix, cy - iy)
      ..lineTo(rect.right, cy)
      ..lineTo(cx + ix, cy + iy)
      ..lineTo(cx, rect.bottom)
      ..lineTo(cx - ix, cy + iy)
      ..lineTo(rect.left, cy)
      ..lineTo(cx - ix, cy - iy)
      ..close();
  }

  Path _hourglassPath(Rect rect) {
    return Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.center.dx, rect.center.dy)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.center.dx, rect.center.dy)
      ..close();
  }

  Path _butterflyPath(Rect rect) {
    final path = Path();
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final w = rect.width;
    final h = rect.height;
    path.addOval(
      Rect.fromCenter(
        center: Offset(cx - w * 0.28, cy - h * 0.16),
        width: w * 0.58,
        height: h * 0.52,
      ),
    );
    path.addOval(
      Rect.fromCenter(
        center: Offset(cx - w * 0.22, cy + h * 0.22),
        width: w * 0.44,
        height: h * 0.42,
      ),
    );
    path.addOval(
      Rect.fromCenter(
        center: Offset(cx + w * 0.28, cy - h * 0.16),
        width: w * 0.58,
        height: h * 0.52,
      ),
    );
    path.addOval(
      Rect.fromCenter(
        center: Offset(cx + w * 0.22, cy + h * 0.22),
        width: w * 0.44,
        height: h * 0.42,
      ),
    );
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: w * 0.14,
          height: h * 0.82,
        ),
        Radius.circular(w * 0.07),
      ),
    );
    return path;
  }

  Path _xMarkPath(Rect rect) {
    final inset = rect.shortestSide * 0.18;
    final arm = rect.shortestSide * 0.18;
    final path = Path();
    void addArm(Offset a, Offset b) {
      final dx = b.dx - a.dx;
      final dy = b.dy - a.dy;
      final len = math.sqrt(dx * dx + dy * dy);
      final nx = -dy / len * arm / 2;
      final ny = dx / len * arm / 2;
      path.addPolygon(
        [
          Offset(a.dx + nx, a.dy + ny),
          Offset(a.dx - nx, a.dy - ny),
          Offset(b.dx - nx, b.dy - ny),
          Offset(b.dx + nx, b.dy + ny),
        ],
        true,
      );
    }

    addArm(
      Offset(rect.left + inset, rect.top + inset),
      Offset(rect.right - inset, rect.bottom - inset),
    );
    addArm(
      Offset(rect.right - inset, rect.top + inset),
      Offset(rect.left + inset, rect.bottom - inset),
    );
    return path;
  }

  int _moduleAccentSeed(int x, int y) => (x * 73856093) ^ (y * 19349663);

  Color _accentColor(int seed, Color base) {
    if (gradient != null) {
      return base;
    }
    const palette = <Color>[
      Color(0xff7c4dff),
      Color(0xff2979ff),
      Color(0xffff6d00),
      Color(0xff00bfa5),
      Color(0xfff50057),
    ];
    return palette[seed.abs() % palette.length];
  }

  Path _roundRect(Rect rect, double fraction) {
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect,
          Radius.circular(rect.shortestSide * fraction),
        ),
      );
  }

  Path _cornerRadiiPath(
    Rect rect, {
    double topLeft = 0,
    double topRight = 0,
    double bottomLeft = 0,
    double bottomRight = 0,
  }) {
    return Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: Radius.circular(rect.shortestSide * topLeft),
          topRight: Radius.circular(rect.shortestSide * topRight),
          bottomLeft: Radius.circular(rect.shortestSide * bottomLeft),
          bottomRight: Radius.circular(
            rect.shortestSide * bottomRight,
          ),
        ),
      );
  }

  Path _leafOutline(Rect rect) {
    return _cornerRadiiPath(
      rect,
      topLeft: 0.22,
      topRight: 0,
      bottomRight: 0.38,
      bottomLeft: 0.55,
    );
  }

  Path _bittenOval(Rect rect) {
    final oval = Path()..addOval(rect);
    final cutter = Path()
      ..moveTo(
        rect.right - rect.width * 0.02,
        rect.top + rect.height * 0.62,
      )
      ..lineTo(rect.right + rect.width, rect.top + rect.height * 0.62)
      ..lineTo(rect.right + rect.width, rect.bottom + rect.height)
      ..lineTo(rect.left + rect.width * 0.62, rect.bottom + rect.height)
      ..lineTo(
        rect.left + rect.width * 0.62,
        rect.bottom - rect.height * 0.02,
      )
      ..close();
    return Path.combine(PathOperation.difference, oval, cutter);
  }

  void _drawEyeRing(
    Canvas canvas,
    Path outer,
    Path hole,
    Paint framePaint, {
    Path? pupil,
    Paint? pupilPaint,
  }) {
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, hole),
      framePaint,
    );
    if (pupil != null) {
      canvas.drawPath(pupil, pupilPaint ?? framePaint);
    }
  }

  Paint _eyeStroke(Color color, double width) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = color;
  }

  Paint _eyeFill(
    Color color, {
    Gradient? gradient,
    Rect? bounds,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = color;
    if (gradient != null && bounds != null) {
      paint.shader = gradient.createShader(bounds);
    }
    return paint;
  }

  _FigmaEyeTheme _figmaEyeTheme(QrEyeShape shape, Color fallback) {
    if (!eyeStyle.useFigmaColors) {
      return _FigmaEyeTheme(frame: fallback, pupil: fallback);
    }
    switch (shape) {
      case QrEyeShape.dottedSlash:
        return const _FigmaEyeTheme(
          frame: Color(0xffb4e600),
          pupil: Color(0xffb4e600),
        );
      case QrEyeShape.bear:
        return const _FigmaEyeTheme(
          frame: Color(0xffff4fa3),
          pupil: Color(0xffff4fa3),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xffff6eb4), Color(0xffb13de0)],
          ),
        );
      case QrEyeShape.roundedCircle:
        return const _FigmaEyeTheme(
          frame: Color(0xffff7a18),
          pupil: Color(0xffff7a18),
          accent: Color(0xffffc4a8),
        );
      case QrEyeShape.dottedMatrix:
        return const _FigmaEyeTheme(
          frame: Color(0xffff7a18),
          pupil: Color(0xff3d7eff),
          accent: Color(0xff9b4dff),
        );
      case QrEyeShape.pumpkin:
        return const _FigmaEyeTheme(
          frame: Color(0xff1f1f1f),
          pupil: Color(0xff1f1f1f),
          accent: Color(0xffff2d2d),
        );
      case QrEyeShape.windowGrid:
        return const _FigmaEyeTheme(
          frame: Color(0xff3b5bdb),
          pupil: Color(0xff3b5bdb),
        );
      case QrEyeShape.glitch:
        return const _FigmaEyeTheme(
          frame: Color(0xff111111),
          pupil: Color(0xff111111),
          accent: Color(0xffff4fd8),
        );
      case QrEyeShape.leafCircle:
        return const _FigmaEyeTheme(
          frame: Color(0xff1a1028),
          pupil: Color(0xff3ddc84),
        );
      case QrEyeShape.gift:
        return const _FigmaEyeTheme(
          frame: Color(0xff3b5bdb),
          pupil: Color(0xff3b5bdb),
        );
      case QrEyeShape.circleStar:
        return const _FigmaEyeTheme(
          frame: Color(0xff2ecc71),
          pupil: Color(0xff2ecc71),
        );
      case QrEyeShape.basketball:
        return const _FigmaEyeTheme(
          frame: Color(0xffff6a00),
          pupil: Color(0xffff6a00),
          accent: Color(0xff5d3310),
        );
      case QrEyeShape.play:
        return const _FigmaEyeTheme(
          frame: Color(0xffff2d2d),
          pupil: Color(0xffff2d2d),
          accent: Color(0xffb71c1c),
        );
      case QrEyeShape.paw:
        return const _FigmaEyeTheme(
          frame: Color(0xff2f5bea),
          pupil: Color(0xff2f5bea),
          accent: Color(0xff8fa6ff),
        );
      case QrEyeShape.splitCircle:
        return const _FigmaEyeTheme(
          frame: Color(0xff4da3ff),
          pupil: Color(0xff4da3ff),
          accent: Color(0xff1e6fd8),
        );
      case QrEyeShape.clover:
        return const _FigmaEyeTheme(
          frame: Color(0xff7CFC00),
          pupil: Color(0xff7CFC00),
        );
      case QrEyeShape.gradientRing:
        return const _FigmaEyeTheme(
          frame: Color(0xffff6a00),
          pupil: Color(0xffff2d9b),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xffff8a00), Color(0xffff2d9b)],
          ),
        );
      case QrEyeShape.squareHeart:
        return const _FigmaEyeTheme(
          frame: Color(0xffff2d9b),
          pupil: Color(0xffff2d9b),
        );
      default:
        return _FigmaEyeTheme(frame: fallback, pupil: fallback);
    }
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
        final dotAssetId = _dotAssetId(dataModuleStyle.dataModuleShape);
        // Keep procedural square when corner-radius styling is requested.
        final useDotAsset = dotAssetId != null &&
            !(dotAssetId == 1 &&
                (dataModuleStyle.borderRadius > 0 ||
                    isRoundedOutsideCorners));
        if (useDotAsset) {
          if (isDark) {
            var drawRect = squareRect;
            // Connect horizontal / vertical capsules like the Figma samples.
            if (dataModuleStyle.dataModuleShape ==
                QrDataModuleShape.barHorizontal) {
              final leftDark = _isDarkOnSide(
                x - 1,
                y,
                safeAreaRect,
                paintMetrics,
                gap,
              );
              final rightDark = _isDarkOnSide(
                x + 1,
                y,
                safeAreaRect,
                paintMetrics,
                gap,
              );
              var left = squareRect.left;
              var width = squareRect.width;
              if (leftDark) {
                left -= gap.toDouble() / 2;
                width += gap.toDouble() / 2;
              }
              if (rightDark) {
                width += gap.toDouble() / 2;
              }
              final h = squareRect.height *
                  (leftDark || rightDark ? 0.72 : 0.78);
              drawRect = Rect.fromCenter(
                center: Offset(left + width / 2, squareRect.center.dy),
                width: width,
                height: h,
              );
            } else if (dataModuleStyle.dataModuleShape ==
                QrDataModuleShape.barVertical) {
              final topDark = _isDarkOnSide(
                x,
                y - 1,
                safeAreaRect,
                paintMetrics,
                gap,
              );
              final bottomDark = _isDarkOnSide(
                x,
                y + 1,
                safeAreaRect,
                paintMetrics,
                gap,
              );
              var top = squareRect.top;
              var height = squareRect.height;
              if (topDark) {
                top -= gap.toDouble() / 2;
                height += gap.toDouble() / 2;
              }
              if (bottomDark) {
                height += gap.toDouble() / 2;
              }
              final w = squareRect.width *
                  (topDark || bottomDark ? 0.72 : 0.78);
              drawRect = Rect.fromCenter(
                center: Offset(squareRect.center.dx, top + height / 2),
                width: w,
                height: height,
              );
            }
            drawDotSvgModule(
              canvas,
              drawRect,
              dotAssetId,
              paint,
              seed: _moduleAccentSeed(x, y),
            );
          }
          continue;
        }
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

          case QrDataModuleShape.roundDot:
            if (isDark) {
              canvas.drawOval(squareRect, paint);
            }
            break;

          case QrDataModuleShape.rhombus:
            if (isDark) {
              canvas.drawPath(_regularPolygon(squareRect, 4), paint);
            }
            break;

          case QrDataModuleShape.sparkle:
            if (isDark) {
              canvas.drawPath(_sparkleDotPath(squareRect), paint);
            }
            break;

          case QrDataModuleShape.triangle:
            if (isDark) {
              canvas.drawPath(_trianglePath(squareRect), paint);
            }
            break;

          case QrDataModuleShape.heart:
            if (isDark) {
              canvas.drawPath(_heartPath(squareRect), paint);
            }
            break;

          case QrDataModuleShape.softSquare:
            if (isDark) {
              canvas.drawRRect(
                RRect.fromRectAndRadius(
                  squareRect,
                  Radius.circular(squareRect.width * 0.28),
                ),
                paint,
              );
            }
            break;

          case QrDataModuleShape.plus:
            if (isDark) {
              canvas.drawPath(_plusPath(squareRect), paint);
            }
            break;

          case QrDataModuleShape.barHorizontal:
            if (isDark) {
              final leftDark = _isDarkOnSide(
                x - 1,
                y,
                safeAreaRect,
                paintMetrics,
                gap,
              );
              final rightDark = _isDarkOnSide(
                x + 1,
                y,
                safeAreaRect,
                paintMetrics,
                gap,
              );
              final barHeight = squareRect.height *
                  (leftDark || rightDark ? 0.55 : 0.72);
              var left = squareRect.left;
              var width = squareRect.width;
              if (leftDark) {
                left -= gap.toDouble() / 2;
                width += gap.toDouble() / 2;
              }
              if (rightDark) {
                width += gap.toDouble() / 2;
              }
              final bar = Rect.fromCenter(
                center: Offset(left + width / 2, squareRect.center.dy),
                width: width,
                height: barHeight,
              );
              canvas.drawRRect(
                RRect.fromRectAndRadius(
                  bar,
                  Radius.circular(barHeight / 2),
                ),
                paint,
              );
            }
            break;

          case QrDataModuleShape.barVertical:
            if (isDark) {
              final topDark = _isDarkOnSide(
                x,
                y - 1,
                safeAreaRect,
                paintMetrics,
                gap,
              );
              final bottomDark = _isDarkOnSide(
                x,
                y + 1,
                safeAreaRect,
                paintMetrics,
                gap,
              );
              final barWidth = squareRect.width *
                  (topDark || bottomDark ? 0.55 : 0.72);
              var top = squareRect.top;
              var height = squareRect.height;
              if (topDark) {
                top -= gap.toDouble() / 2;
                height += gap.toDouble() / 2;
              }
              if (bottomDark) {
                height += gap.toDouble() / 2;
              }
              final bar = Rect.fromCenter(
                center: Offset(squareRect.center.dx, top + height / 2),
                width: barWidth,
                height: height,
              );
              canvas.drawRRect(
                RRect.fromRectAndRadius(
                  bar,
                  Radius.circular(barWidth / 2),
                ),
                paint,
              );
            }
            break;

          case QrDataModuleShape.mixedHeart:
            if (isDark) {
              final seed = _moduleAccentSeed(x, y);
              if (seed % 8 == 0) {
                canvas.drawPath(
                  _heartPath(squareRect.inflate(squareRect.width * 0.55)),
                  paint,
                );
              } else {
                canvas.drawOval(squareRect, paint);
              }
            }
            break;

          case QrDataModuleShape.mixedBlob:
            if (isDark) {
              final seed = _moduleAccentSeed(x, y);
              if (seed % 9 == 0) {
                canvas.drawOval(
                  squareRect.inflate(squareRect.width * 0.75),
                  paint,
                );
              } else {
                canvas.drawOval(squareRect, paint);
              }
            }
            break;

          case QrDataModuleShape.mixedButterfly:
            if (isDark) {
              final seed = _moduleAccentSeed(x, y);
              if (seed % 8 == 0) {
                canvas.drawPath(
                  _butterflyPath(
                    squareRect.inflate(squareRect.width * 0.65),
                  ),
                  paint,
                );
              } else {
                canvas.drawOval(squareRect, paint);
              }
            }
            break;

          case QrDataModuleShape.mixedSpecial:
            if (isDark) {
              final seed = _moduleAccentSeed(x, y);
              final accentPaint = Paint()
                ..style = PaintingStyle.fill
                ..isAntiAlias = true
                ..color = _accentColor(seed, paint.color);
              final kind = seed.abs() % 14;
              if (kind == 0) {
                canvas.drawRRect(
                  RRect.fromRectAndRadius(
                    squareRect.inflate(squareRect.width * 0.85),
                    Radius.circular(squareRect.width * 0.4),
                  ),
                  accentPaint,
                );
              } else if (kind <= 2) {
                canvas.drawPath(
                  _xMarkPath(squareRect.inflate(squareRect.width * 0.2)),
                  accentPaint,
                );
              } else {
                canvas.drawOval(squareRect, accentPaint);
              }
            }
            break;

          case QrDataModuleShape.hourglass:
            if (isDark) {
              canvas.drawPath(_hourglassPath(squareRect), paint);
            }
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

    // Fill-based eyes need the full 7x7 finder bounds. Stroke eyes draw on a
    // centered path that visually expands by half a module on each side.
    // Figma eyes use a thicker frame and a larger pupil than classic 7-5-3.
    final frameRect = outerRect.inflate(strokeAdjust);
    final holeRect = frameRect.deflate(metrics.pixelSize * 1.15);
    final pupilRect = frameRect.deflate(metrics.pixelSize * 1.7);

    final theme = _figmaEyeTheme(eyeStyle.eyeShape, color);
    final frameColor = eyeStyle.frameColor ?? theme.frame;
    final pupilColor = eyeStyle.pupilColor ?? theme.pupil;
    final accentColor = eyeStyle.accentColor ?? theme.accent ?? pupilColor;
    final eyeGradient = eyeStyle.gradient ?? theme.gradient;

    final framePaint = _eyeFill(
      frameColor,
      gradient: eyeGradient,
      bounds: frameRect,
    );
    final pupilPaint = _eyeFill(
      pupilColor,
      gradient: eyeGradient,
      bounds: pupilRect,
    );
    final accentPaint = _eyeFill(accentColor);
    const octagonTurn = -math.pi / 2 + math.pi / 8;

    // Draw Figma SVG assets exactly when this eye shape maps to an export.
    // Skip the mono-tint SVG path when frame/pupil colors are set so the
    // procedural dual-color branch (frameColor + pupilColor) can run.
    final eyeAssetId = _eyeAssetId(eyeStyle.eyeShape);
    final hasCustomEyeColors =
        eyeStyle.frameColor != null || eyeStyle.pupilColor != null;
    if (eyeAssetId != null && !hasCustomEyeColors) {
      drawEyeSvgAsset(
        canvas,
        frameRect,
        eyeAssetId,
        tint: eyeStyle.useFigmaColors ? null : color,
      );
      return;
    }

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

      case QrEyeShape.diamondSquare:
        _drawEyeRing(
          canvas,
          Path()..addRect(frameRect),
          Path()..addRect(holeRect),
          framePaint,
          pupil: _regularPolygon(pupilRect, 4),
          pupilPaint: pupilPaint,
        );
        break;

      case QrEyeShape.arch:
        {
          Path uShape(Rect rect) {
            final r = rect.shortestSide * 0.46;
            final path = Path()
              ..moveTo(rect.left, rect.top)
              ..lineTo(rect.right, rect.top)
              ..lineTo(rect.right, rect.bottom - r)
              ..arcToPoint(
                Offset(rect.left, rect.bottom - r),
                radius: Radius.circular(rect.width / 2),
                clockwise: false,
              )
              ..close();
            return path;
          }

          _drawEyeRing(
            canvas,
            uShape(frameRect),
            uShape(holeRect),
            framePaint,
            pupil: uShape(pupilRect.deflate(pupilRect.shortestSide * 0.02)),
            pupilPaint: pupilPaint,
          );
        }
        break;

      case QrEyeShape.starCut:
        _drawEyeRing(
          canvas,
          Path()..addRect(frameRect),
          Path()..addRect(holeRect),
          framePaint,
          pupil: _fourPointStar(pupilRect, pull: 0.12),
          pupilPaint: pupilPaint,
        );
        break;

      case QrEyeShape.circleBite:
        _drawEyeRing(
          canvas,
          _bittenOval(frameRect),
          _bittenOval(holeRect),
          framePaint,
          pupil: _bittenOval(
            pupilRect.deflate(pupilRect.shortestSide * 0.02),
          ),
          pupilPaint: pupilPaint,
        );
        break;

      case QrEyeShape.octagon:
        _drawEyeRing(
          canvas,
          _regularPolygon(frameRect, 8, rotation: octagonTurn),
          _regularPolygon(holeRect, 8, rotation: octagonTurn),
          framePaint,
          pupil: _regularPolygon(pupilRect, 8, rotation: octagonTurn),
          pupilPaint: pupilPaint,
        );
        break;

      case QrEyeShape.roundedDiamond:
        _drawEyeRing(
          canvas,
          _roundRect(frameRect, 0.32),
          _roundRect(holeRect, 0.28),
          framePaint,
          pupil: _regularPolygon(pupilRect, 4),
          pupilPaint: pupilPaint,
        );
        break;

      case QrEyeShape.singleRound:
        _drawEyeRing(
          canvas,
          _cornerRadiiPath(
            frameRect,
            topLeft: 0.55,
            topRight: 0.08,
            bottomLeft: 0.08,
            bottomRight: 0.08,
          ),
          _cornerRadiiPath(
            holeRect,
            topLeft: 0.5,
            topRight: 0.06,
            bottomLeft: 0.06,
            bottomRight: 0.06,
          ),
          framePaint,
          pupil: _cornerRadiiPath(
            pupilRect,
            topLeft: 0.55,
            topRight: 0.08,
            bottomLeft: 0.08,
            bottomRight: 0.08,
          ),
          pupilPaint: pupilPaint,
        );
        break;

      case QrEyeShape.circleSpark:
        _drawEyeRing(
          canvas,
          Path()..addOval(frameRect),
          Path()..addOval(holeRect),
          framePaint,
          pupil: _fourPointStar(pupilRect, pull: 0.12),
          pupilPaint: pupilPaint,
        );
        break;

      case QrEyeShape.octagonTriangle:
        _drawEyeRing(
          canvas,
          _regularPolygon(frameRect, 8, rotation: octagonTurn),
          _regularPolygon(holeRect, 8, rotation: octagonTurn),
          framePaint,
          pupil: _trianglePath(pupilRect),
          pupilPaint: pupilPaint,
        );
        break;

      case QrEyeShape.squareHeart:
        _drawEyeRing(
          canvas,
          _roundRect(frameRect, 0.28),
          _roundRect(holeRect, 0.24),
          framePaint,
          pupil: _heartPath(pupilRect),
          pupilPaint: pupilPaint,
        );
        break;

      case QrEyeShape.circlePillVertical:
        _drawEyeRing(
          canvas,
          Path()..addOval(frameRect),
          Path()..addOval(holeRect),
          framePaint,
          pupil: _roundRect(
            Rect.fromCenter(
              center: pupilRect.center,
              width: pupilRect.width * 0.58,
              height: pupilRect.height * 0.95,
            ),
            0.5,
          ),
          pupilPaint: pupilPaint,
        );
        break;

      case QrEyeShape.circlePillHorizontal:
        _drawEyeRing(
          canvas,
          Path()..addOval(frameRect),
          Path()..addOval(holeRect),
          framePaint,
          pupil: _roundRect(
            Rect.fromCenter(
              center: pupilRect.center,
              width: pupilRect.width * 0.95,
              height: pupilRect.height * 0.58,
            ),
            0.5,
          ),
          pupilPaint: pupilPaint,
        );
        break;

      case QrEyeShape.octagonCross:
        {
          _drawEyeRing(
            canvas,
            _regularPolygon(frameRect, 8, rotation: octagonTurn),
            _regularPolygon(holeRect, 8, rotation: octagonTurn),
            framePaint,
          );
          final cross = pupilRect.deflate(pupilRect.shortestSide * 0.02);
          final crossPaint = _eyeStroke(
            pupilColor,
            metrics.pixelSize * 0.85,
          );
          canvas.drawLine(cross.topLeft, cross.bottomRight, crossPaint);
          canvas.drawLine(cross.topRight, cross.bottomLeft, crossPaint);
        }
        break;

      case QrEyeShape.dottedSlash:
        {
          final leaf = _leafOutline(frameRect);
          final dashPaint = _eyeStroke(
            frameColor,
            metrics.pixelSize * 0.85,
          )..strokeCap = StrokeCap.round;
          for (final metric in leaf.computeMetrics()) {
            var d = 0.0;
            const dash = 10.0;
            const gapLen = 7.0;
            while (d < metric.length) {
              final next = math.min(d + dash, metric.length);
              canvas.drawPath(metric.extractPath(d, next), dashPaint);
              d = next + gapLen;
            }
          }
          canvas.drawPath(
            Path.combine(
              PathOperation.difference,
              _leafOutline(pupilRect),
              Path()
                ..moveTo(pupilRect.left, pupilRect.top)
                ..lineTo(pupilRect.right, pupilRect.bottom)
                ..lineTo(
                  pupilRect.right - pupilRect.width * 0.12,
                  pupilRect.bottom,
                )
                ..lineTo(
                  pupilRect.left,
                  pupilRect.top + pupilRect.height * 0.12,
                )
                ..close(),
            ),
            pupilPaint,
          );
        }
        break;

      case QrEyeShape.bear:
        {
          final earRadius = frameRect.shortestSide * 0.18;
          final head = pupilRect.deflate(pupilRect.shortestSide * 0.02);
          canvas.drawCircle(
            Offset(
              head.left + earRadius * 0.35,
              head.top + earRadius * 0.15,
            ),
            earRadius,
            pupilPaint,
          );
          canvas.drawCircle(
            Offset(
              head.right - earRadius * 0.35,
              head.top + earRadius * 0.15,
            ),
            earRadius,
            pupilPaint,
          );
          _drawEyeRing(
            canvas,
            Path()..addOval(frameRect),
            Path()..addOval(holeRect),
            framePaint,
            pupil: Path()..addOval(head),
            pupilPaint: pupilPaint,
          );
        }
        break;

      case QrEyeShape.windowGrid:
        {
          _drawEyeRing(
            canvas,
            _leafOutline(frameRect),
            _leafOutline(holeRect),
            framePaint,
          );
          final gridGap = pupilRect.width * 0.16;
          final cell = (pupilRect.width - gridGap) / 2;
          for (var row = 0; row < 2; row++) {
            for (var col = 0; col < 2; col++) {
              canvas.drawRect(
                Rect.fromLTWH(
                  pupilRect.left + col * (cell + gridGap),
                  pupilRect.top + row * (cell + gridGap),
                  cell,
                  cell,
                ),
                pupilPaint,
              );
            }
          }
        }
        break;

      case QrEyeShape.leafCircle:
        _drawEyeRing(
          canvas,
          _leafOutline(frameRect),
          _leafOutline(holeRect),
          framePaint,
          pupil: Path()..addOval(pupilRect),
          pupilPaint: pupilPaint,
        );
        break;

      case QrEyeShape.gift:
        {
          _drawEyeRing(
            canvas,
            _roundRect(frameRect, 0.28),
            _roundRect(holeRect, 0.24),
            framePaint,
          );
          final icon = _eyeStroke(pupilColor, metrics.pixelSize * 0.45);
          final box = Rect.fromLTWH(
            pupilRect.left + pupilRect.width * 0.08,
            pupilRect.top + pupilRect.height * 0.36,
            pupilRect.width * 0.84,
            pupilRect.height * 0.56,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              box,
              Radius.circular(pupilRect.shortestSide * 0.06),
            ),
            icon,
          );
          canvas.drawLine(
            Offset(pupilRect.center.dx, box.top),
            Offset(pupilRect.center.dx, box.bottom),
            icon,
          );
          final bandY = box.top + box.height * 0.28;
          canvas.drawLine(
            Offset(box.left, bandY),
            Offset(box.right, bandY),
            icon,
          );
          final bowY = box.top - pupilRect.height * 0.02;
          canvas.drawCircle(
            Offset(
              pupilRect.center.dx - pupilRect.width * 0.14,
              bowY,
            ),
            pupilRect.shortestSide * 0.11,
            icon,
          );
          canvas.drawCircle(
            Offset(
              pupilRect.center.dx + pupilRect.width * 0.14,
              bowY,
            ),
            pupilRect.shortestSide * 0.11,
            icon,
          );
        }
        break;

      case QrEyeShape.circleStar:
        _drawEyeRing(
          canvas,
          Path()..addOval(frameRect),
          Path()..addOval(holeRect),
          framePaint,
          pupil: _starPolygon(pupilRect, 5, innerRatio: 0.42),
          pupilPaint: pupilPaint,
        );
        break;

      case QrEyeShape.basketball:
        {
          _drawEyeRing(
            canvas,
            Path()..addOval(frameRect),
            Path()..addOval(holeRect),
            framePaint,
            pupil: Path()..addOval(pupilRect),
            pupilPaint: pupilPaint,
          );
          final seam = _eyeStroke(accentColor, metrics.pixelSize * 0.45);
          canvas.drawLine(
            Offset(pupilRect.left, pupilRect.center.dy),
            Offset(pupilRect.right, pupilRect.center.dy),
            seam,
          );
          canvas.drawLine(
            Offset(pupilRect.center.dx, pupilRect.top),
            Offset(pupilRect.center.dx, pupilRect.bottom),
            seam,
          );
          canvas.drawPath(
            Path()
              ..moveTo(pupilRect.center.dx, pupilRect.top)
              ..quadraticBezierTo(
                pupilRect.left + pupilRect.width * 0.08,
                pupilRect.center.dy,
                pupilRect.center.dx,
                pupilRect.bottom,
              ),
            seam,
          );
          canvas.drawPath(
            Path()
              ..moveTo(pupilRect.center.dx, pupilRect.top)
              ..quadraticBezierTo(
                pupilRect.right - pupilRect.width * 0.08,
                pupilRect.center.dy,
                pupilRect.center.dx,
                pupilRect.bottom,
              ),
            seam,
          );
        }
        break;

      case QrEyeShape.play:
        {
          _drawEyeRing(
            canvas,
            _roundRect(frameRect, 0.32),
            _roundRect(holeRect, 0.28),
            framePaint,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              pupilRect,
              Radius.circular(pupilRect.shortestSide * 0.22),
            ),
            pupilPaint,
          );
          canvas.drawPath(
            Path()
              ..moveTo(
                pupilRect.left + pupilRect.width * 0.32,
                pupilRect.top + pupilRect.height * 0.22,
              )
              ..lineTo(
                pupilRect.right - pupilRect.width * 0.22,
                pupilRect.center.dy,
              )
              ..lineTo(
                pupilRect.left + pupilRect.width * 0.32,
                pupilRect.bottom - pupilRect.height * 0.22,
              )
              ..close(),
            accentPaint,
          );
        }
        break;

      case QrEyeShape.roundedCircle:
        {
          _drawEyeRing(
            canvas,
            _roundRect(frameRect, 0.34),
            _roundRect(holeRect, 0.3),
            framePaint,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              pupilRect,
              Radius.circular(pupilRect.shortestSide * 0.28),
            ),
            pupilPaint,
          );
          canvas.drawOval(
            pupilRect.deflate(pupilRect.shortestSide * 0.22),
            accentPaint,
          );
        }
        break;

      case QrEyeShape.paw:
        {
          _drawEyeRing(
            canvas,
            _roundRect(frameRect, 0.32),
            _roundRect(holeRect, 0.28),
            framePaint,
          );
          canvas.drawOval(pupilRect, pupilPaint);
          final toeRadius = pupilRect.shortestSide * 0.13;
          final toes = <Offset>[
            Offset(
              pupilRect.center.dx - pupilRect.width * 0.28,
              pupilRect.top + pupilRect.height * 0.28,
            ),
            Offset(
              pupilRect.center.dx,
              pupilRect.top + pupilRect.height * 0.14,
            ),
            Offset(
              pupilRect.center.dx + pupilRect.width * 0.28,
              pupilRect.top + pupilRect.height * 0.28,
            ),
          ];
          for (final toe in toes) {
            canvas.drawCircle(toe, toeRadius, accentPaint);
          }
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(
                pupilRect.center.dx,
                pupilRect.bottom - pupilRect.height * 0.30,
              ),
              width: pupilRect.width * 0.62,
              height: pupilRect.height * 0.40,
            ),
            accentPaint,
          );
        }
        break;

      case QrEyeShape.splitCircle:
        {
          _drawEyeRing(
            canvas,
            _roundRect(frameRect, 0.32),
            _roundRect(holeRect, 0.28),
            framePaint,
          );
          canvas.drawRect(pupilRect, pupilPaint);
          canvas.drawPath(
            Path()
              ..moveTo(pupilRect.left, pupilRect.top)
              ..lineTo(pupilRect.right, pupilRect.top)
              ..lineTo(pupilRect.left, pupilRect.bottom)
              ..close(),
            accentPaint,
          );
        }
        break;

      case QrEyeShape.dottedMatrix:
        {
          final step = frameRect.width / 6;
          final dotR = metrics.pixelSize * 0.42;
          for (var i = 0; i < 7; i++) {
            final topBottom = _eyeFill(
              i == 0 || i == 6 ? frameColor : frameColor,
            );
            final side = _eyeFill(accentColor);
            canvas.drawCircle(
              Offset(frameRect.left + step * i, frameRect.top),
              dotR,
              topBottom,
            );
            canvas.drawCircle(
              Offset(frameRect.left + step * i, frameRect.bottom),
              dotR,
              topBottom,
            );
            if (i > 0 && i < 6) {
              canvas.drawCircle(
                Offset(frameRect.left, frameRect.top + step * i),
                dotR,
                side,
              );
              canvas.drawCircle(
                Offset(frameRect.right, frameRect.top + step * i),
                dotR,
                side,
              );
            }
          }
          final cell = pupilRect.width / 3;
          for (var row = 0; row < 3; row++) {
            for (var col = 0; col < 3; col++) {
              canvas.drawCircle(
                Offset(
                  pupilRect.left + cell * col + cell / 2,
                  pupilRect.top + cell * row + cell / 2,
                ),
                cell * 0.28,
                pupilPaint,
              );
            }
          }
        }
        break;

      case QrEyeShape.pumpkin:
        {
          _drawEyeRing(
            canvas,
            _leafOutline(frameRect),
            _leafOutline(holeRect),
            framePaint,
          );
          canvas.drawOval(pupilRect, pupilPaint);
          final face = accentPaint;
          canvas.drawPath(
            _trianglePath(
              Rect.fromCenter(
                center: Offset(
                  pupilRect.center.dx - pupilRect.width * 0.18,
                  pupilRect.center.dy - pupilRect.height * 0.08,
                ),
                width: pupilRect.width * 0.18,
                height: pupilRect.height * 0.18,
              ),
            ),
            face,
          );
          canvas.drawPath(
            _trianglePath(
              Rect.fromCenter(
                center: Offset(
                  pupilRect.center.dx + pupilRect.width * 0.18,
                  pupilRect.center.dy - pupilRect.height * 0.08,
                ),
                width: pupilRect.width * 0.18,
                height: pupilRect.height * 0.18,
              ),
            ),
            face,
          );
          canvas.drawArc(
            Rect.fromCenter(
              center: Offset(
                pupilRect.center.dx,
                pupilRect.center.dy + pupilRect.height * 0.12,
              ),
              width: pupilRect.width * 0.55,
              height: pupilRect.height * 0.35,
            ),
            0.15,
            math.pi - 0.3,
            false,
            _eyeStroke(accentColor, metrics.pixelSize * 0.35),
          );
        }
        break;

      case QrEyeShape.glitch:
        {
          final cyan = _eyeStroke(const Color(0xff00e5ff), metrics.pixelSize);
          final pink = _eyeStroke(const Color(0xffff4fd8), metrics.pixelSize);
          final black = _eyeStroke(frameColor, metrics.pixelSize * 1.05);
          final shape = _roundRect(frameRect, 0.28);
          canvas.save();
          canvas.translate(-metrics.pixelSize * 0.35, 0);
          canvas.drawPath(shape, cyan);
          canvas.restore();
          canvas.save();
          canvas.translate(metrics.pixelSize * 0.35, 0);
          canvas.drawPath(shape, pink);
          canvas.restore();
          canvas.drawPath(shape, black);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              pupilRect,
              Radius.circular(pupilRect.shortestSide * 0.22),
            ),
            pupilPaint,
          );
        }
        break;

      case QrEyeShape.clover:
        {
          _drawEyeRing(
            canvas,
            _roundRect(frameRect, 0.32),
            _roundRect(holeRect, 0.28),
            framePaint,
          );
          final leafSize = pupilRect.shortestSide * 0.42;
          final centers = <Offset>[
            Offset(
              pupilRect.center.dx,
              pupilRect.center.dy - leafSize * 0.45,
            ),
            Offset(
              pupilRect.center.dx,
              pupilRect.center.dy + leafSize * 0.45,
            ),
            Offset(
              pupilRect.center.dx - leafSize * 0.45,
              pupilRect.center.dy,
            ),
            Offset(
              pupilRect.center.dx + leafSize * 0.45,
              pupilRect.center.dy,
            ),
          ];
          for (final c in centers) {
            canvas.drawOval(
              Rect.fromCenter(
                center: c,
                width: leafSize,
                height: leafSize,
              ),
              pupilPaint,
            );
          }
        }
        break;

      case QrEyeShape.gradientRing:
        _drawEyeRing(
          canvas,
          Path()..addOval(frameRect),
          Path()..addOval(holeRect),
          framePaint,
          pupil: Path()..addOval(pupilRect),
          pupilPaint: pupilPaint,
        );
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

class _FigmaEyeTheme {
  const _FigmaEyeTheme({
    required this.frame,
    required this.pupil,
    this.accent,
    this.gradient,
  });

  final Color frame;
  final Color pupil;
  final Color? accent;
  final Gradient? gradient;
}
