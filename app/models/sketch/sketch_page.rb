require 'dimensions'

class SketchPage < ActiveRecord::Base
  has_many :sketch_artboards, dependent: :destroy, inverse_of: :sketch_file

  def self.new_from_path(page_config, path)
    # Sketch lies about the right and bottom bounds, so we'll recalculate them.
    left, top, _right, _bottom = page_config['bounds'].split(',').map(&:to_f)
    page_width, page_height = Dimensions.dimensions(File.join(path, page_config['name'] + '.png'))

    SketchPage.new(
      uuid: page_config['id'],
      name: page_config['name'],
      bounds: [left, top, left + page_width, top + page_height].join(','),
    )
  end
end
