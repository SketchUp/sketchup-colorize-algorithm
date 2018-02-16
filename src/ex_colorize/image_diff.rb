require 'stringio'

require 'ex_colorize/image_rep_helper'


module Example::Colorize
  class ImageDiff

    attr_reader :mismatchs

    PixelDiff = Struct.new(:index, :color1, :color2, :match, :delta)

    def initialize(image_rep1, image_rep2)
      unless image_rep1.width == image_rep2.width &&
             image_rep1.height == image_rep2.height
        raise ArgumentError, "bitmaps must be of the same dimensions"
      end
      @width = image_rep1.width
      @height = image_rep1.height
      @mismatchs = {}
      colors1 = image_rep1.colors
      colors2 = image_rep2.colors
      colors1.each_with_index { |color1, i|
        color2 = colors2[i]
        next if color2 == color1
        @mismatchs[i] = pixel_diff(i, color1, color2)
      }
    end

    def difference
      num_pixels = @width * @height
      colors = num_pixels.times.map { |i|
        mismatch = @mismatchs[i]
        mismatch ? mismatch : Sketchup::Color.new(0, 0, 0)
      }
      image_rep = Sketchup::ImageRep.new
      ImageRepHelper.colors_to_image_rep(image_rep, colors)
      image_rep
    end

    def report
      num_pixels = @width * @height
      num_matching = num_pixels - @mismatchs.size
      total_match = (num_matching / num_pixels) * 100.0
      report = StringIO.new
      report.puts "Matching pixels: #{num_matching} (#{total_match.round(2)}%)"
      deviance = 0.0
      @mismatchs.each { |i, diff|
      deviance += diff.match
        report.puts "#{diff.index.to_s.rjust(5)}: #{diff.color1} <=> #{diff.color2} = #{diff.delta} (#{(diff.match * 100).round(2)})"
      }
      average_deviance = deviance / @mismatchs.size
      report.puts "Average Deviance: #{(average_deviance * 100).round(2)}%"
      report.string
    end

    private

    def pixel_diff(index, color1, color2)
      delta = pixel_delta(color1, color2)
      match = pixel_match(delta)
      PixelDiff.new(index, color1, color2, match, delta)
    end

    def pixel_delta(color1, color2)
      r1, g1, b1, a1 = color1.to_a
      r2, g2, b2, a2 = color2.to_a
      r = (r1 - r2).abs
      g = (g1 - g2).abs
      b = (b1 - b2).abs
      a = (a1 - a2).abs
      Sketchup::Color.new(r, g, b, a)
    end

    def pixel_match(delta)
      r = delta.red.to_f / 255.0
      g = delta.green.to_f / 255.0
      b = delta.blue.to_f / 255.0
      a = delta.alpha.to_f / 255.0
      (r + g + b + a) / 4.0
    end

  end # class
end # module
