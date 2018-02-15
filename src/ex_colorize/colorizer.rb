module Example::Colorize
  class Colorizer

    def colorize(image_rep, colorize_hsl)
      process(image_rep, colorize_hsl, false)
    end

    def shift(image_rep, shift_hsl)
      process(image_rep, shift_hsl, true)
    end

    def process(image_rep, hsl_delta, shift)
      puts "process (hsl: #{hsl_delta}, shift: #{shift})"
      colors = image_rep.colors.map { |color|
        colorize_pixel(color, hsl_delta, shift)
      }
      # p image_rep.colors[0, 10].map(&:to_a)
      # p colors[0, 10].map(&:to_a)
      colors_to_image_rep(image_rep, colors)
    end

    private

    def colors_to_image_rep(image_rep, colors)
      width = image_rep.width
      height = image_rep.height
      row_padding = 0
      # TODO: SketchUp appear to crash with 32bit colors (RGBA)
      #       Investigate why. This should work with alpha channels.
      # bits_per_pixel = 32
      # pixel_data = colors.map(&:to_a).flatten.pack('C*')
      bits_per_pixel = 24
      unless colors.all? { |color| color.is_a?(Sketchup::Color) }
        none_colors = colors.select { |color| !color.is_a?(Sketchup::Color) }
        p none_colors
        raise "Expected only Sketchup::Color objects (#{none_colors.size} of #{colors.size})"
      end
      # TODO: Apparently the colors needs to be BGR - at least on Windows.
      #       Is this platform dependant?
      #       Missing API feature?
      #
      #       C API expose SUColorOrder - which Ruby API is missing.
      #
      #       > SketchUpAPI expects the channels to be in different orders on
      #       > Windows vs. Mac OS. Bitmap data is exposed in BGRA and RGBA byte
      #       > orders on Windows and Mac OS, respectively.
      #
      # TODO: Typo in the description of SUColorOrder.
      # NOTE: SUGetColorOrder(); should have been named SUImageRepGetRGBOrder().
      pixel_data = colors.map { |c| c.to_a[0, 3].reverse }.flatten.pack('C*')
      unless width * height * 3 == pixel_data.size
        puts "Expected: #{width * height * 3} - actual: #{pixel_data.size}"
        raise 'Invalid data!'
      end
      image_rep.set_data(width, height, bits_per_pixel, row_padding, pixel_data)
      image_rep
    end

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

      while ph < 0.0 # TODO: With tolerance
        ph += 360.0
      end

      while ph > 360.0 # TODO: With tolerance
        ph -= 360.0
      end

      # Shift saturation
      ps += s
      ps = clamp(ps, 0.0, 1.0)

      # Shift lumination
      pl += l
      pl = clamp(pl, 0.01, 1.0)

      # Convert back to rgb and reassign
      if ps == 0.0 # TODO: With tolerance
        r, g, b = saturation2rgb(ps)
        Sketchup::Color.new(r, g, b)
      else
        r, g, b = hls2rgb(ph, pl, ps)
        Sketchup::Color.new(r, g, b)
      end
    end

    def saturation2rgb(s)
      [s, s, s]
    end

    def rgb2hls(r, g, b, a = 255)
      h = l = s = 0.0

      r = byte2float(r)
      g = byte2float(g)
      b = byte2float(b)

      max = [r, g, b].max.to_f
      min = [r, g, b].min.to_f

      # Lightness
      l = (max + min) / 2.0

      # Saturation and Hue
      if min == max # TODO: With tolerance
        # Achromatic
        s = 0.0
        h = -1.0
      else
        # Chromatic
        if l <= 0.5 # TODO: With tolerance
          s = (max - min) / (max + min)
        else
          s = (max - min) / (2.0 - max - min)
        end

        # Hue
        rc = (max - r) / (max - min)
        gc = (max - g) / (max - min)
        bc = (max - b) / (max - min)

        if r == max # TODO: With tolerance
          h = bc - gc # color between yellow and magenta
        elsif g == max # TODO: With tolerance
          h = 2.0 + rc - bc # color between cyan and yellow
        elsif b == max # TODO: With tolerance
          h = 4.0 + gc - rc # color between magenta and cyan
        end

        h = h * 60
        if h < 0.0 # TODO: With tolerance
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
      if l < 0.5 # TODO: With tolerance
        m2 = l * (1.0 + s)
      else
        m2 = l + s - (l * s)
      end
      m1 = 2.0 * l - m2

      # acromatic
      if s == 0.0 # TODO: With tolerance
        if h == -1.0 # TODO: With tolerance
          r = g = b = l
        else
          raise 'assert'
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
      # Sketchup::Color.new(rb, gb, bb)
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
      if hue > 360.0 # TODO: With tolerance
        hue -= 360.0
      end
      if hue < 0.0 # TODO: With tolerance
        hue += 360.0
      end
      if hue < 60.0 # TODO: With tolerance
        value = n1 + (n2 - n1) * hue / 60
      elsif hue < 180.0 # TODO: With tolerance
        value = n2
      elsif hue < 240.0 # TODO: With tolerance
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
      value.to_f / 255.0
    end


    # CMaterial::GetColorizeDeltas
    def material_deltas(material)
      rv = false
      if material.texture && material.materialType == Sketchup::Material::MATERIAL_COLORIZED_TEXTURED
        shift = material.colorize_type = Sketchup::Material::COLORIZE_SHIFT
        hls = texture_deltas(texture, material.color, shift)
        return hls
      end
      rv
    end

    # CTexture::GetColorizeDeltas
    def texture_deltas(texture, color, shift)
      base_color = texture.average_color
      get_params(base_color, color, shift)
    end

    # Colorize::GetParameters
    # "params" == deltas?
    def get_params(from, to, shift)
      # Get the hls of the base color
      baseH, baseL, baseS = rgb2hls(*from.to_a)

      # Get the hls of the new color
      h, l, s = rgb2hls(*to.to_a)

      # If both colors are monochrome
      if monochrome?(to) && monochrome?(from)
        h = 0;          # no hue change
        s = 0;          # no saturation change
        l = l - baseL;  # delta the lumination
      elsif monochrome?(to)
        h = 0;          # no hue change
        s = -1;         # saturation is forcing all to monochrome
        l = l - baseL;  # delta the lumination
      elsif monochrome?(from)
        # h = h         # use new hue
        # s = s         # use new saturation
        l = l - baseL;  # delta the lumination
      else
        # Find the delta values
        # If we are shifting, we need the delta of all the values.
        # If we are tinting, we only need delta of l and s only.
        l = l - baseL;
        s = s - baseS;
        # if( s < 0 ) s = 1.0;
        if (bShift)
          h = h - baseH;
        end
      end

      [h, l, s]
    end

    def monochrome?(color)
      color.r = color.g && color.g == color.b
    end

  end
end # module
