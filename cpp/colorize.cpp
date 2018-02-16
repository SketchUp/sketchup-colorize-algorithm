#include "colorize.h"

#include <assert.h>
#include <math.h> /* fabs */


namespace sketchup {
namespace {

const double EqualTol = 1.0e-3;

bool LessThan(double val1, double val2) {
  return (val1 - val2) <= -EqualTol;
}

bool GreaterThan(double val1, double val2) {
  return (val1 - val2) >= EqualTol;
}

bool Equals(double val1, double val2) {
  return fabs(val1 - val2) < EqualTol;
}

bool LessThanOrEqual(double val1, double val2) {
  return LessThan(val1, val2) || Equals(val1, val2);
}

double Clamp(double val, double min, double max) {
  if (val < min)
    return min;
  else if (val > max)
    return max;
  return val;
}

inline BYTE Double01ToByte(double val) {
  if (val <= 0.0) {
    return 0;
  } else if (val >= 1.0) {
    return 255;
  } else {
    return static_cast<BYTE>(val * 255.0);
  }
}

inline float ByteToFloat(BYTE val) {
  return static_cast<float>(val) / 255.0f;
}

HLS RGB2HSL(const RGBA& color)
{
  auto rb = color.r;
  auto gb = color.g;
  auto bb = color.b;

  double h, l, s;

  // Convert to double (0.0 - 1.0)
  double r = ByteToFloat(rb);
  double g = ByteToFloat(gb);
  double b = ByteToFloat(bb);

  // Convert to HLS.
  double max, min;
  max = r;
  if (GreaterThan(g, max))
    max = g;
  if (GreaterThan(b, max))
    max = b;
  min = r;
  if (LessThan(g, min))
    min = g;
  if (LessThan(b, min))
    min = b;

  // Lightness
  l = (max + min) / 2.0;

  // saturation and hue
  if (Equals(min, max)) {
    // Achromatic
    s = 0.0;
    h = -1.0;    // undefined
  } else {
    // Chromatic

    // Saturation
    if (LessThanOrEqual(l, 0.5)) {
      s = (max - min) / (max + min);
    } else {
      s = (max - min) / (2 - max - min);
    }

    // Hue
    double rc = (max - r) / (max - min);
    double gc = (max - g) / (max - min);
    double bc = (max - b) / (max - min);

    if (Equals(r, max)) {
      h = bc - gc;            // color between yellow and magenta
    } else if (Equals(g, max)) {
      h = 2 + rc - bc;        // color between cyan and yellow
    } else if (Equals(b, max)) {
      h = 4 + gc - rc;        // color between magenta and cyan
    }

    h = h * 60;
    if (LessThan(h, 0.0)) {
      h = h + 360;
    }
  }
  return HLS{ h, l, s };
}

double CalcValue(double n1, double n2, double hue) {
  double value;
  if (GreaterThan(hue, 360.0) ) {
    hue -= 360.0;
  }
  if (LessThan(hue, 0.0) ) {
    hue += 360;
  }
  if (LessThan(hue, 60.0) ) {
    value = n1 + (n2 - n1) * hue / 60;
  } else if (LessThan(hue, 180) ) {
    value = n2;
  } else if (LessThan(hue, 240) ) {
    value = n1 + (n2 - n1) * (240 - hue) / 60.0;
  } else {
    value = n1;
  }
  return value;
}

RGBA HLSToRGB(double h, double l, double s)
{
  // double values for color
  double r = l, g = l, b = l;

  // Figure out the color
  double m1, m2;
  if (LessThan(l, 0.5) ) {
    m2 = l * (1.0 + s);
  } else {
    m2 = l + s - (l * s);
  }
  m1 = 2 * l - m2;

  if (Equals(s, 0.0) ) {
    // Achromatic
    if (Equals(h, -1) ) {
      r = g = b = l;
    } else {
      //ASSERT(0);
      assert(false);
    }
  } else {
    // Chromatic
    r = CalcValue(m1, m2, h + 120);
    g = CalcValue(m1, m2, h);
    b = CalcValue(m1, m2, h - 120);
  }

  auto rb = Double01ToByte(r);
  auto gb = Double01ToByte(g);
  auto bb = Double01ToByte(b);
  return RGBA{ rb, gb, bb };
}

RGBA LuminanceToRGB(double luminance)
{
  auto l = Double01ToByte(luminance);
  return RGBA{ l, l, l };
}

bool IsMonochrome(const RGBA& color)
{
  return color.r == color.g && color.g && color.b;
}

} // namespace


/*
 * \param color
 * \param delta HLS delta See Ruby API SketchUp::Material#colorize_deltas
 * \param shift
 */
RGBA Colorize(const RGBA& color, const HLS& delta, bool shift)
{
  // Convert to HLS
  auto color_hsl = RGB2HSL(color);
  auto h = color_hsl.h;
  auto l = color_hsl.l;
  auto s = color_hsl.s;

  // Colorize
  if (shift) {
    // Shift Hue
    h += delta.h;
  } else {
    // Clamp Hue
    h = delta.h;
  }
  while (LessThan(h, 0.0)) {
    h += 360.0;
  }
  while (GreaterThan(h, 360.0)) {
    h -= 360.0;
  }

  // Shift Saturation
  s += delta.s;
  s = Clamp(s, 0.0, 1.0);

  // Shift Luminance
  l += delta.l;
  l = Clamp(l, 0.01, 1.0);

  // Convert back to rgb and reassign
  RGBA rgb;
  if (Equals(s, 0.0)) {
    rgb = LuminanceToRGB(l);
  } else {
    rgb = HLSToRGB(h, l, s);
  }

  // Preserve the alpha channel
  rgb.a = color.a;

  return rgb;
}


HLS GetColorizeDeltas(const RGBA& from, const RGBA& to, bool shift)
{
  // Get the HLS of the base color
  auto base = RGB2HSL(from);

  // Get the hls of the new color
  auto toHLS = RGB2HSL(to);
  double h = toHLS.h, l = toHLS.l, s = toHLS.s;

  // If both colors are monochrome
  if (IsMonochrome(to) && IsMonochrome(from)) {
    h = 0;           // no hue change
    s = 0;           // no saturation change
    l = l - base.l;  // delta the luminance
  } else if (IsMonochrome(to)) {
    h = 0;           // no hue change
    s = -1;          // saturation is forcing all to monochrome
    l = l - base.l;  // delta the luminance
  } else if (IsMonochrome(from)) {
    l = l - base.l;  // delta the luminance
  } else {
    // Find the delta values
    // If we are shifting, we need the delta of all the values.
    // If we are tinting, we only need delta of l and s only.
    l = l - base.l;
    s = s - base.s;
    if (shift) {
      h = h - base.h;
    }
  }

  return HLS{ h, l, s };
}
  
} // namespace
