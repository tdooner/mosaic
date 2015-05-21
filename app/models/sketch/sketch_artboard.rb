class SketchArtboard < ActiveRecord::Base
  belongs_to :sketch_file

  def self.new_from_path(artboard_config, path)
    bounds = {
      left: artboard_config['trimmed']['x'],
      right: artboard_config['trimmed']['x'] + artboard_config['trimmed']['width'],
      top: artboard_config['trimmed']['y'],
      bottom: artboard_config['trimmed']['y'] + artboard_config['trimmed']['height'],
    }

    SketchArtboard.new(
      uuid: artboard['id'],
      name: artboard['name'],
      bounds: bounds.values_at(:left, :top, :right, :bottom).join(','),
    )
  end
end
