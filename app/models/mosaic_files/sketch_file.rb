class SketchFile < MosaicFile
  has_many :sketch_pages
  register_file_type '.sketch'

  def enqueue_sync!
    ProcessSketchWorker.call(id)
  end
end
