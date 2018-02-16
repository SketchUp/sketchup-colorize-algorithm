module Example::Colorize
  class ImageRepHelper

    IS_WIN = Sketchup.platform == :platform_win

    def self.colors_to_image_rep(image_rep, colors)
      width = image_rep.width
      height = image_rep.height
      row_padding = 0
      # TODO: SketchUp appear to crash with 32bit colors (RGBA)
      #       Investigate why. This should work with alpha channels.
      # bits_per_pixel = 32
      # pixel_data = colors.map(&:to_a).flatten.pack('C*')
      bits_per_pixel = 24
      pixel_data = self.colors_to_24bit_bytes(colors)
      unless width * height * 3 == pixel_data.size
        puts "Expected: #{width * height * 3} - actual: #{pixel_data.size}"
        raise 'Invalid data!'
      end
      image_rep.set_data(width, height, bits_per_pixel, row_padding, pixel_data)
      image_rep
    end

    # From C API documentation on SUColorOrder
    #
    # > SketchUpAPI expects the channels to be in different orders on
    # > Windows vs. Mac OS. Bitmap data is exposed in BGRA and RGBA byte
    # > orders on Windows and Mac OS, respectively.
    def self.color_to_32bit(color)
      r, g, b, a = color.to_a
      IS_WIN ? [b, g, r, a] : [r, g, b, a]
    end

    def self.colors_to_32bit_bytes(colors)
      colors.map { |color| self.color_to_32bit(color) }.flatten.pack('C*')
    end

    def self.color_to_24bit(color)
      self.color_to_32bit(color)[0, 3]
    end

    def self.colors_to_24bit_bytes(colors)
      colors.map { |color| self.color_to_24bit(color) }.flatten.pack('C*')
    end

  end # class
end # module
