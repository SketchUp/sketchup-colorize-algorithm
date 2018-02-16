require 'ex_colorize/image_rep_helper'


module Example::Colorize
  class Colorizer

    def colorize(image_rep, hsl_delta)
      process(image_rep, hsl_delta, false)
    end

    def shift(image_rep, hsl_delta)
      process(image_rep, hsl_delta, true)
    end

    def process(image_rep, hsl_delta, shift)
      colors = image_rep.colors.map { |color|
        colorize_pixel(color, hsl_delta, shift)
      }
      ImageRepHelper.colors_to_image_rep(image_rep, colors)
    end

    private

    def colorize_pixel(color, hls, shift)
      h, l, s = hls

      ph, pl, ps = rgb2hls(*color.to_a)

      if shift
        # Shift Hue
        ph += h
      else
        # Clamp Hue
        ph = h
      end

      while less_than(ph, 0.0)
        ph += 360.0
      end

      while greater_than(ph, 360.0)
        ph -= 360.0
      end

      # Shift saturation
      ps += s
      ps = clamp(ps, 0.0, 1.0)

      # Shift lumination
      pl += l
      pl = clamp(pl, 0.01, 1.0)

      # Convert back to rgb and reassign
      if equals(ps, 0.0)
        r, g, b = luminance2rgb(pl)
        Sketchup::Color.new(r, g, b)
      else
        r, g, b = hls2rgb(ph, pl, ps)
        Sketchup::Color.new(r, g, b)
      end
    end

    def luminance2rgb(s)
      r = g = b = double2byte(s)
      [r, g, b]
    end

    def rgb2hls(r, g, b, a = 255)
      h = l = s = 0.0

      r = byte2float(r)
      g = byte2float(g)
      b = byte2float(b)

      # max = [r, g, b].max.to_f
      # min = [r, g, b].min.to_f
      # The original code compared with tolerance. Not seeing the point of that
      # in this case, but for the sake of being true to the implementation we
      # do that here as well.
      max = min = r
      max = g if greater_than(g, max)
      max = b if greater_than(b, max)
      min = g if less_than(g, min)
      min = b if less_than(b, min)

      # Lightness
      l = (max + min) / 2.0

      # Saturation and Hue
      if equals(min, max)
        # Achromatic
        s = 0.0
        h = -1.0
      else
        # Chromatic
        if less_than_or_equal(l, 0.5)
          s = (max - min) / (max + min)
        else
          s = (max - min) / (2.0 - max - min)
        end

        # Hue
        rc = (max - r) / (max - min)
        gc = (max - g) / (max - min)
        bc = (max - b) / (max - min)

        if equals(r, max)
          h = bc - gc # color between yellow and magenta
        elsif equals(g, max)
          h = 2.0 + rc - bc # color between cyan and yellow
        elsif equals(b, max)
          h = 4.0 + gc - rc # color between magenta and cyan
        end

        h = h * 60
        if less_than(h, 0.0)
          h = h + 360.0
        end
      end

      [h, l, s]
    end

    def hls2rgb(h, l, s)
      # double values for color
      r = g = b = l

      # Figure out the color
      m1 = m2 = 0.0
      if less_than(l, 0.5)
        m2 = l * (1.0 + s)
      else
        m2 = l + s - (l * s)
      end
      m1 = 2.0 * l - m2

      # acromatic
      if equals(s, 0.0)
        if equals(h, -1.0)
          r = g = b = l
        else
          raise 'assert' # Remove for release!
        end
      else
        # chromatic
        r = calc_value(m1, m2, h + 120.0)
        g = calc_value(m1, m2, h)
        b = calc_value(m1, m2, h - 120.0)
      end

      rb = double2byte(r)
      gb = double2byte(g)
      bb = double2byte(b)
      [rb, gb, bb]
    end

    def clamp(value, min, max)
      if value < min
        return min
      elsif value > max
        return max
      end
      value
    end

    def calc_value(n1, n2, hue)
      value = 0.0
      if greater_than(hue, 360.0)
        hue -= 360.0
      end
      if less_than(hue, 0.0)
        hue += 360.0
      end
      if less_than(hue, 60.0)
        value = n1 + (n2 - n1) * hue / 60
      elsif less_than(hue, 180.0)
        value = n2
      elsif less_than(hue, 240.0)
        value = n1 + (n2 - n1) * (240.0 - hue) / 60.0
      else
        value = n1
      end
      value
    end

    def double2byte(value)
      if value <= 0.0
        return 0
      elsif value >= 1.0
        return 255
      else
        (value * 255).to_i
      end
    end

    def byte2float(value)
      # NOTE:
      # Original C++ implementation:
      #   return (float) val / 255.0f;
      # In ruby, Float uses double, but with one less precision bit.
      # Example, given 166:
      #   C++ (float)  0.650980413
      #   C++ (double) 0.65098039215686276
      #   Ruby         0.6509803921568628
      # This difference is enough to produce deviance in the RGB channels by
      # a value of 1 in the final results.
      value.to_f / 255.0
    end


    # Comparisons for CColor

    EQUAL_TOL = 1.0e-3

    def less_than(val1, val2)
      (val1 - val2) <= -EQUAL_TOL
    end

    def greater_than(val1, val2)
      (val1 - val2) >= EQUAL_TOL
    end

    def equals(val1, val2)
      (val1 - val2).abs < EQUAL_TOL
    end

    def less_than_or_equal(val1, val2)
      less_than(val1, val2) || equals(val1, val2)
    end

  end # class
end # module
