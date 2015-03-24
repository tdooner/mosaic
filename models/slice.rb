class Slice < ActiveRecord::Base
  THREE_DAYS = 3 * 24 * 60 * 60

  belongs_to :sketch_file

  after_commit :create_thumbnail

  scope :recently_modified, -> do
    joins('INNER JOIN sketch_files on sketch_files.id = slices.sketch_file_id')
    .where('sketch_files.last_modified >= ?', Time.now - THREE_DAYS)
    .order('sketch_files.last_modified DESC')
  end
  scope :not_recently_modified, -> do
    joins(:sketch_file)
      .where.not(sketch_files: { last_modified: (Time.now - THREE_DAYS)..Time.now })
  end

  def create_thumbnail
    full_path = File.expand_path("../../#{path}", __FILE__)
    $logger.info 'Creating thumbnail for ' + full_path
    `convert -thumbnail 300 -extent 300x600 #{full_path} #{full_path.gsub('.png', '.thumb.jpg')}`
  end

  def self.find_by_search(query)
    search_tokens = query.split(/[^\w]/)
    search_tokens.map! { |t| "#{t}*" }

    # TODO: Parameterize this query:
    where('slices MATCH ?', search_tokens.join(' '))
  end
end
