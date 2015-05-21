class SketchArtboard < ActiveRecord::Base
  belongs_to :sketch_file

  after_create :index
  before_destroy :unindex

  def self.new_from_path(artboard_config, path)
    bounds = {
      left: artboard_config['trimmed']['x'],
      right: artboard_config['trimmed']['x'] + artboard_config['trimmed']['width'],
      top: artboard_config['trimmed']['y'],
      bottom: artboard_config['trimmed']['y'] + artboard_config['trimmed']['height'],
    }

    SketchArtboard.new(
      uuid: artboard_config['id'],
      name: artboard_config['name'],
      bounds: bounds.values_at(:left, :top, :right, :bottom).join(','),
    )
  end

  def unindex
    self.class.connection.execute "DELETE FROM artboards_fts WHERE artboard_id = #{id}"
  end

  def index
    unindex
    self.class.connection.execute "INSERT INTO artboards_fts (artboard_id, body) VALUES (#{id}, \"#{name}\");"
  end
end
