require 'sketchup.rb'

require 'ex_colorize/colorizer'


module Example::Colorize

  unless file_loaded?(__FILE__)
    menu = UI.menu('Plugins').add_submenu('SketchUp Colorization')
    menu.add_item('Colorize') { self.colorize_images }
    menu.add_separator
    menu.add_item('Validate') { self.validate }
    file_loaded(__FILE__)
  end

  def self.colorize_images
    if Sketchup.version.to_i < 18
      message = 'Requires SketchUp 2018 or newer'
      UI.messagebox(message)
      raise message
    end

    # TODO: Make sure the example.skp model is opened.

    model = Sketchup.active_model
    image = model.entities.grep(Sketchup::Image).first

    model.start_operation('Colorize')

    shift_hsl = model.materials['Shifted'].colorize_deltas
    shifted_face = self.create_tile(image, 3.m)
    self.shift_material(shifted_face, shift_hsl)

    colorized_hsl = model.materials['Colorized'].colorize_deltas
    colorized_face = self.create_tile(image, 6.m)
    self.colorize_material(colorized_face, colorized_hsl)

    model.commit_operation

    {
      shifted_face => model.materials['Shifted'],
      colorized_face => model.materials['Colorized'],
    }
  end

  def self.validate
    Sketchup.status_text = "Colorizing..."
    mismatchs = []
    self.colorize_images.each { |face, original_material|
      Sketchup.status_text = "Comparing #{original_material.display_name}..."
      original_colors = original_material.texture.image_rep.colors
      generated_colors = face.material.texture.image_rep.colors
      original_colors.each_with_index { |original_color, i|
        generated_color = generated_colors[i]
        next if generated_color == original_color
        # raise "Color mismatch at #{i} (Expected: #{original_color}, Actual: #{generated_color})"
        mismatchs << [i, original_color, generated_color]
      }
    }
    if mismatchs.empty?
      puts "Shiny! :)"
    else
      # TODO: Display result in using Resemble:
      #       https://huddle.github.io/Resemble.js/
      report = mismatchs.map { |i, original_color, generated_color|
        "Color mismatch at #{i} (Expected: #{original_color}, Actual: #{generated_color})"
      }
      puts report.join("\n")
    end
  end

  def self.shift_material(face, hsl_delta)
    self.process_material(face, hsl_delta, true)
  end

  def self.colorize_material(face, hsl_delta)
    self.process_material(face, hsl_delta, false)
  end

  def self.process_material(face, hsl_delta, shift)
    model = face.model
    image_rep = face.material.texture.image_rep
    colorizer = Colorizer.new
    material_name = shift ? 'Shifted' : 'Colorized'
    material = model.materials.add('Shifted')
    material.texture = colorizer.process(image_rep, hsl_delta, shift)
    w = face.material.texture.width
    h = face.material.texture.height
    material.texture.size = [w, h]
    face.material = material
    face.back_material = material
    material
  end

  def self.create_tile(image, offset)
    x = offset
    y = 0
    w = x + image.width
    h = image.height
    points = [
      Geom::Point3d.new(x, y, 0),
      Geom::Point3d.new(w, y, 0),
      Geom::Point3d.new(w, h, 0),
      Geom::Point3d.new(x, h, 0),
    ]
    group = image.model.entities.add_group
    face = group.entities.add_face(points)
    material = image.model.materials['Original']
    mapping = [
      points[0], Geom::Point3d.new(0, 0, 0),
      points[1], Geom::Point3d.new(1, 0, 0),
      points[2], Geom::Point3d.new(1, 1, 0),
      points[3], Geom::Point3d.new(0, 1, 0),
    ]
    face.position_material(material, mapping, true)
    face.position_material(material, mapping, false)
    face
  end


  # @note Debug method to reload the extension.
  #
  # @example
  #   Example::Colorize.reload
  def self.reload
    original_verbose = $VERBOSE
    $VERBOSE = nil
    # Core file (this)
    load __FILE__
    # Supporting files
    if defined?(PATH) && File.exist?(PATH)
      pattern = File.join(PATH, '**/*.rb')
      x = Dir.glob(pattern).each { |file|
        load file
      }
      x.length + 1
    else
      1
    end
  ensure
    $VERBOSE = original_verbose
  end

end # module
