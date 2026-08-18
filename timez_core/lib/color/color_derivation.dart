// Spec: docs/03-domain-model.md §5, §10 "Color"; docs/04-radial-geometry.md
// §10 "Contrast" (computed here alongside color derivation, per that doc).
//
// The engine computes color; it does not know what a `Color` is — colors
// are opaque 32-bit ARGB ints (0xAARRGGBB).

import 'dart:math' as math;

import 'package:timez_core/entities/tag.dart';

/// Returned by [deriveColor] for an untagged block. The UI maps this to its
/// theme's default color; the engine never invents one. Alpha `0x00` makes
/// this unambiguous — a real tag color is always fully opaque.
const int neutralColorSentinel = 0x00000000;

/// The block's rendered color: the ARGB `colorArgb` of the attached tag with
/// the lowest `sortOrder` (the "primary" tag, §5). An untagged block (empty
/// [attachedTags]) returns [neutralColorSentinel]. Completion state is
/// irrelevant here — the engine returns color only, never opacity or a
/// strikethrough; the UI expresses completion separately.
int deriveColor(List<Tag> attachedTags) {
  if (attachedTags.isEmpty) return neutralColorSentinel;

  var primary = attachedTags.first;
  for (final tag in attachedTags.skip(1)) {
    if (tag.sortOrder < primary.sortOrder) {
      primary = tag;
    }
  }
  return primary.colorArgb;
}

/// True when [foregroundArgb] drawn against [backgroundArgb] falls below a
/// 3:1 WCAG contrast ratio — docs/04-radial-geometry.md §10's threshold for
/// drawing a 1dp outline around an otherwise-unreadable tag color.
bool needsContrastOutline(int foregroundArgb, int backgroundArgb) {
  return _contrastRatio(foregroundArgb, backgroundArgb) < 3.0;
}

double _contrastRatio(int argbA, int argbB) {
  final luminanceA = _relativeLuminance(argbA);
  final luminanceB = _relativeLuminance(argbB);
  final lighter = math.max(luminanceA, luminanceB);
  final darker = math.min(luminanceA, luminanceB);
  return (lighter + 0.05) / (darker + 0.05);
}

/// WCAG 2.x relative luminance: https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
double _relativeLuminance(int argb) {
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  return 0.2126 * _linearize(r) +
      0.7152 * _linearize(g) +
      0.0722 * _linearize(b);
}

double _linearize(int channel8Bit) {
  final c = channel8Bit / 255.0;
  return c <= 0.03928
      ? c / 12.92
      : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}
