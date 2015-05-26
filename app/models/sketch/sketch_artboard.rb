class SketchArtboard < ActiveRecord::Base
  belongs_to :sketch_page
 
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
    self.class.connection.execute "INSERT INTO artboards_fts (artboard_id, body) VALUES (#{id}, #{self.class.sanitize(name)});"
  end

  def image_path(thumbnail=false)
    safe_name = name.scan(/\w+/).join('-')
    File.join(sketch_page.sketch_file.image_path, "#{safe_name}#{thumbnail ? '.thumb.jpg' : '.png'}")
  end

  def serializable_hash(options)
    super.merge(image_path: image_path, thumbnail_path: image_path(true))
  end
end
