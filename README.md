# SketchUp Colorize Algorithm

This is a documentation of how SketchUp colorize materials using HLS shifting
or tinting.

The original implementation is in C++. This example is rewritten in Ruby.
Beware minor precision differences where the original source used single
precision `float` compared to Ruby which always uses double precision. This have
been noted in the source code.
