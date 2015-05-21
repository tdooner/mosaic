class MosaicFile < ActiveRecord::Base
  scope :in_sync, -> { where(in_sync: true) }

  def self.register_file_type(type)
    @@types ||= {}
    @@types[type] = self
  end

  def self.file_types
    @@types ||= {}
    @@types
  end

  def self.sync_all
    update_all(in_sync: false)
  end

  def enqueue_sync!
    raise NotImplementedError
  end
end