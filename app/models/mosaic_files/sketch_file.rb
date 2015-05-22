class SketchFile < MosaicFile
  has_many :sketch_pages, dependent: :destroy
  has_many :sketch_artboards, through: :sketch_pages
  register_file_type '.sketch'

  def enqueue_sync!
    Threaded.enqueue(ProcessSketchWorker, id)
  end
end
