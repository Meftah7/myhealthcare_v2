/// The Care Navigator mascot: its three pieces of artwork, a widget that draws
/// one of them precisely, and the round blue avatar shared by the floating
/// launcher and the chat panel header so the two always match.
library;

import 'package:flutter/material.dart';

/// One mascot PNG and the rectangle (in source pixels) its visible artwork
/// occupies. The files are 1254×1254 canvases with transparent padding around
/// the art (plus a few near-invisible specks below alpha 16); drawing just
/// [content] lets the art be sized precisely, and lets a head's cut edge sit
/// exactly on the page edge with no transparent gap.
///
/// Asset names must stay URL-safe (no spaces): the web build writes each file
/// under its URL-encoded name, which static hosts then fail to serve.
class MascotArt {
  const MascotArt(this.asset, this.content);

  static const double canvas = 1254;

  final String asset;
  final Rect content;

  double get aspect => content.width / content.height;

  /// Decoded at roughly the size it is drawn, not the full 1254px canvas.
  ImageProvider provider(double height, double dpr) {
    final scale = height / content.height;
    return ResizeImage(
      AssetImage(asset),
      width: (canvas * scale * dpr).ceil(),
      policy: ResizeImagePolicy.fit,
    );
  }
}

// Bounds measured from the alpha channel (alpha > 16) of each file.

/// The whole mascot, standing, hands lowered.
const mascotFullBody = MascotArt(
  'assets/images/care_navigator_full_body.png',
  Rect.fromLTRB(211, 83, 1013, 1153),
);

/// Head cut off at its left edge (x = 0) and peeking right: docks on the left.
const mascotHeadLeft = MascotArt(
  'assets/images/care_navigator_head_left.png',
  Rect.fromLTRB(0, 109, 752, 1086),
);

/// Head cut off at its right edge (x = 1254) and peeking left: docks on the
/// right.
const mascotHeadRight = MascotArt(
  'assets/images/care_navigator_head_right.png',
  Rect.fromLTRB(470, 113, 1254, 1082),
);

/// Draws [art]'s [MascotArt.content] at [height], keeping its aspect ratio.
class MascotImage extends StatelessWidget {
  const MascotImage(this.art, {required this.height, super.key});

  final MascotArt art;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scale = height / art.content.height;
    final canvas = MascotArt.canvas * scale;
    return SizedBox(
      width: height * art.aspect,
      height: height,
      // Stack clips to its box by default: only the art's content shows.
      child: Stack(
        children: [
          Positioned(
            left: -art.content.left * scale,
            top: -art.content.top * scale,
            width: canvas,
            height: canvas,
            child: Image(
              image: art.provider(
                height,
                MediaQuery.devicePixelRatioOf(context),
              ),
              fit: BoxFit.fill,
              gaplessPlayback: true,
              excludeFromSemantics: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// The Care Navigator's face: the full-body mascot inside a blue circle. The
/// floating launcher draws it at 56dp and the chat header at a smaller size;
/// the mascot keeps the same proportion of the circle at every size.
class CareNavigatorAvatar extends StatelessWidget {
  const CareNavigatorAvatar({this.size = 56, super.key});

  /// The circle's diameter.
  final double size;

  /// How tall the mascot stands inside the circle, as a share of its
  /// diameter (44dp in the 56dp launcher).
  static const double mascotShare = 44 / 56;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.primary,
    shape: const CircleBorder(),
    clipBehavior: Clip.antiAlias,
    child: SizedBox(
      width: size,
      height: size,
      child: Center(
        child: MascotImage(mascotFullBody, height: size * mascotShare),
      ),
    ),
  );
}
