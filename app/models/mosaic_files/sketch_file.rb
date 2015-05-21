class SketchFile < MosaicFile
  has_many :sketch_pages, dependent: :destroy
  register_file_type '.sketch'

  def enqueue_sync!
    Threaded.enqueue(ProcessSketchWorker, id)
  end
end
