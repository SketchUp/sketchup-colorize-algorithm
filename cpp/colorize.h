#pragma once

namespace sketchup {

typedef unsigned char BYTE;

struct RGBA
{
  BYTE r;
  BYTE g;
  BYTE b;
  BYTE a;
};

struct HLS
{
  double h;
  double l;
  double s;
};

/*
 * Replication of the color processing SketchUp performs on colorized materials.
 *
 * \param color
 * \param delta HLS delta See Ruby API SketchUp::Material#colorize_deltas
 * \param shift
 */
RGBA Colorize(const RGBA& color, const HLS& delta, bool shift);

/*
 * Replication of the colorization delta computation SketchUp use for colorized
 * materials. The Ruby API expose this as Sketchup::Material#colorize_deltas,
 * but the C API is currently (SU2018) missing this functionality.
 * 
 * Note in regard to SUTextureGetAverageColor:
 *   The APIs appear to deviate here, the Ruby API return the colorized
 *   average color while the C API return the original color average.
 *     Ruby API: Color(147, 154, 158, 255)
 *        C API: Color(105, 137,  98, 255)
 *
 * \param from Use SUTextureGetAverageColor to get this.
 * \param to Create any SUColor as the target color shift, similar to the UI.
 * \param shift The C API currently (SU2018) lacks getter for this property.
 */
HLS GetColorizeDeltas(const RGBA& from, const RGBA& to, bool shift);
  
} // namespace
