require 'dimensions'

class SketchPage < ActiveRecord::Base
  belongs_to :sketch_file
  has_many :sketch_artboards, dependent: :destroy, inverse_of: :sketch_file

  after_create :index
  before_destroy :unindex

  def self.new_from_path(page_config, path)
    # Sketch lies about the right and bottom bounds, so we'll recalculate them.
    left, top, _right, _bottom = page_config['bounds'].split(',').map(&:to_f)
    page_width, page_height = Dimensions.dimensions(File.join(path, 'pages', page_config['name'] + '.png'))

    SketchPage.new(
      uuid: page_config['id'],
      name: page_config['name'].downcase,
      bounds: [left, top, left + page_width, top + page_height].join(','),
    )
  end

  def unindex
    self.class.connection.execute "DELETE FROM pages_fts WHERE page_id = #{id}"
  end

  def index
    unindex
    self.class.connection.execute "INSERT INTO pages_fts (page_id, body) VALUES (#{id}, \"#{name}\");"
  end
end
