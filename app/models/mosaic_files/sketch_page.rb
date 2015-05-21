require 'dimensions'

class SketchPage < ActiveRecord::Base
  has_many :sketch_artboards, dependent: :destroy, inverse_of: :sketch_file

  def self.load_from_path(path)
    sketch_file = JSON.parse(File.read(File.join(path, 'slices.json')))

    sketch_file['pages'].each do |page|
      # Sketch lies about the right and bottom bounds
      left, top, _right, _bottom = page['bounds'].split(',').map(&:to_f)
      page_width, page_height = Dimensions.dimensions(File.join(path, 'pages', page['name'] + '.png'))

      p = SketchPage.create(
        name: page['name'],
        bounds: [left, top, left + page_width, top + page_height].join(','),
      )

      page['slices'].each do |slice|
        bounds = {
          left: slice['trimmed']['x'],
          right: slice['trimmed']['x'] + slice['trimmed']['width'],
          top: slice['trimmed']['y'],
          bottom: slice['trimmed']['y'] + slice['trimmed']['height'],
        }
        p.sketch_artboards << SketchArtboard.new(
          name: slice['name'],
          bounds: bounds.values_at(:left, :top, :right, :bottom).join(','),
        )
      end

      p.save
    end
  end
end
