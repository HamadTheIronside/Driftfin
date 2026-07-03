import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:driftfin/providers/settings/subtitle_settings_provider.dart';
import 'package:driftfin/providers/settings/video_player_settings_provider.dart';
import 'package:driftfin/util/color_extensions.dart';

part 'subtitle_settings_model.freezed.dart';
part 'subtitle_settings_model.g.dart';

/// Serializes a [Color] to/from the historical `{alpha, red, green, blue}`
/// map (see [ColorExtensions.toMap]/[colorFromJson]). Kept identical to the
/// pre-freezed hand-rolled format so persisted subtitle settings keep loading
/// after the migration (issue #50 Phase 4). [colorFromJson] also still reads
/// the even-older integer color format.
class SubtitleColorConverter implements JsonConverter<Color, Object?> {
  const SubtitleColorConverter();

  @override
  Color fromJson(Object? json) => colorFromJson(json) ?? Colors.white;

  @override
  Object toJson(Color color) => color.toMap;
}

/// Serializes a [FontWeight] as its numeric weight (100–900) — the same
/// `fontWeight.value` the hand-rolled `toMap` wrote. The old `fromMap` looked
/// the weight up by `.index` (0–8) instead, so any non-default weight silently
/// reverted to normal on reload; matching by `.value` here reads that same
/// persisted JSON and now restores the weight the user actually chose.
class FontWeightConverter implements JsonConverter<FontWeight, int> {
  const FontWeightConverter();

  @override
  FontWeight fromJson(int json) =>
      FontWeight.values.firstWhere((weight) => weight.value == json, orElse: () => FontWeight.normal);

  @override
  int toJson(FontWeight object) => object.value;
}

@Freezed(copyWith: true)
abstract class SubtitleSettingsModel with _$SubtitleSettingsModel {
  const SubtitleSettingsModel._();

  const factory SubtitleSettingsModel({
    @Default(60.0) double fontSize,
    @FontWeightConverter() @Default(FontWeight.normal) FontWeight fontWeight,
    @Default(0.10) double verticalOffset,
    @SubtitleColorConverter() @Default(Colors.white) Color color,
    @SubtitleColorConverter() @Default(Color.fromRGBO(0, 0, 0, 0.85)) Color outlineColor,
    @Default(4.0) double outlineSize,
    @SubtitleColorConverter() @Default(Color.fromARGB(0, 0, 0, 0)) Color backGroundColor,
    @Default(0.5) double shadow,
  }) = _SubtitleSettingsModel;

  factory SubtitleSettingsModel.fromJson(Map<String, dynamic> json) => _$SubtitleSettingsModelFromJson(json);

  TextStyle get backGroundStyle {
    return style.copyWith(
      shadows: (shadow > 0.01)
          ? [
              Shadow(
                blurRadius: 16,
                color: Colors.black.withValues(alpha: shadow),
              ),
              Shadow(
                blurRadius: 8,
                color: Colors.black.withValues(alpha: shadow),
              ),
            ]
          : null,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outlineSize * (fontSize / 30)
        ..color = outlineColor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  TextStyle get style {
    return TextStyle(
      height: 1.4,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: 'OpenSans',
      letterSpacing: 0.0,
      wordSpacing: 0.0,
      color: color,
    );
  }

  // freezed is configured with `equal: false` repo-wide (see build.yaml), so
  // value equality is defined here to preserve the pre-migration behavior —
  // the StateNotifier and its listeners rely on two identical settings
  // comparing equal (otherwise every assignment would notify).
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubtitleSettingsModel &&
        other.fontSize == fontSize &&
        other.fontWeight == fontWeight &&
        other.verticalOffset == verticalOffset &&
        other.color == color &&
        other.outlineColor == outlineColor &&
        other.outlineSize == outlineSize &&
        other.backGroundColor == backGroundColor &&
        other.shadow == shadow;
  }

  @override
  int get hashCode => Object.hash(
        fontSize,
        fontWeight,
        verticalOffset,
        color,
        outlineColor,
        outlineSize,
        backGroundColor,
        shadow,
      );
}

class SubtitleText extends ConsumerWidget {
  final SubtitleSettingsModel subModel;
  final EdgeInsets padding;
  final String text;
  final double offset;
  const SubtitleText({
    required this.subModel,
    required this.padding,
    required this.offset,
    required this.text,
    super.key,
  });

  static const kTextScaleFactorReferenceWidth = 1920.0;
  static const kTextScaleFactorReferenceHeight = 1080.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fillScreen = ref.watch(videoPlayerSettingsProvider.select((value) => value.fillScreen));
    final fontSize = ref.read(subtitleSettingsProvider.select((value) => value.fontSize));

    return Padding(
      padding: (fillScreen ? EdgeInsets.zero : EdgeInsets.only(left: padding.left, right: padding.right))
          .add(const EdgeInsets.all(16)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale((fontSize *
              math.sqrt(
                ((constraints.maxWidth * constraints.maxHeight) /
                        (kTextScaleFactorReferenceWidth * kTextScaleFactorReferenceHeight))
                    .clamp(0.0, 1.0),
              )));

          double getTextHeight(BuildContext context, String text, TextStyle style) {
            final TextPainter textPainter = TextPainter(
              text: TextSpan(text: text, style: style),
              textDirection: TextDirection.ltr,
              textScaler: MediaQuery.textScalerOf(context),
            )..layout(minWidth: 0, maxWidth: double.infinity);

            return textPainter.height;
          }

          double availableHeight = constraints.maxHeight;

          final double safeAvailableHeight =
              availableHeight.isFinite ? availableHeight : MediaQuery.of(context).size.height;

          final double desiredPosition = (safeAvailableHeight * offset).clamp(0.0, double.infinity);

          double textHeight = getTextHeight(context, text, subModel.style);
          final double safeTextHeight = textHeight.isFinite ? textHeight : 0.0;

          final double maxPosition = math.max(0.0, safeAvailableHeight - safeTextHeight);

          double position =
              (desiredPosition - safeTextHeight / 2).isFinite ? (desiredPosition - safeTextHeight / 2) : 0.0;

          position = position.clamp(0.0, maxPosition);

          return Visibility(
            visible: text.isEmpty ? false : true,
            child: IgnorePointer(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    bottom: position,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: constraints.maxWidth, maxHeight: constraints.maxHeight),
                      decoration: BoxDecoration(
                        color: subModel.backGroundColor,
                        borderRadius: BorderRadius.circular(clampDouble(textScale / 10, 2, 12)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          text,
                          style: subModel.backGroundStyle.copyWith(fontSize: textScale),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: position,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: constraints.maxWidth, maxHeight: constraints.maxHeight),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          text,
                          style: subModel.style.copyWith(fontSize: textScale),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
