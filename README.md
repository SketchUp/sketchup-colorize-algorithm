# SketchUp Colorize Algorithm

This is a documentation of how SketchUp colorize materials using HLS shifting
or tinting.

## Ruby Variant

Found in `src/ex_colorize/colorizer.rb`.

The original implementation is in C++. This example is rewritten in Ruby.
Beware minor precision differences where the original source used single
precision `float` compared to Ruby which always uses double precision. This have
been noted in the source code.

Open `models/example.skp` and run the tests:
* Extensions > SketchUp Colorization > Colorize
* Extensions > SketchUp Colorization > Validate

## C++ Variant

Found in `cpp/colorize.h` and `cpp/colorize.cpp`.

This will produce the exact same result as SketchUp's own implementation. (At
the time of writing this is SU2018.)
