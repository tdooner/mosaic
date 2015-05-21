class MosaicFile < ActiveRecord::Base
  scope :in_sync, -> { where(in_sync: true) }

  before_save :update_tag_cache
  serialize :tag_cache

  def update_tag_cache(tags = Tagging.all)
    self.tag_cache = tags.find_all do |tag|
      dropbox_path.start_with?(tag.dropbox_path)
    end.map(&:type)
  end

  def self.sync_all
    update_all(in_sync: false)
  end
end
