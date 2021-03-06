#include "colorize.h"

#include <assert.h>


int main()
{
  using namespace sketchup;

  // Test the colorization:
  RGBA color{ 115, 137, 98, 128 };
  HLS delta{ 92.58741048890613, 0.13725490868091583, -0.11229892646129502 };
  auto result = Colorize(color, delta, true);
  RGBA expected{ 147, 156, 158, 128 };
  assert(result.r == expected.r &&
         result.g == expected.g &&
         result.b == expected.b);

  // For reference, this is what the Ruby variant produce due to using
  // double floating point precision for everything.
  RGBA ruby{ 147, 156, 157, 128 };

  // Test the colorization delta:
  RGBA from{ 105, 137, 98, 255 };
  RGBA to{ 147, 154, 158, 255 };
  auto colorization_delta = GetColorizeDeltas(from, to, true);
  HLS expected_delta{ 92.58741048890613, 0.13725490868091583, -0.11229892646129502 };
  assert(colorization_delta.h == expected_delta.h &&
         colorization_delta.l == expected_delta.l &&
         colorization_delta.s == expected_delta.s);

  return 0;
}

