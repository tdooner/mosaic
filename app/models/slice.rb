class Slice < ActiveRecord::Base
  THREE_DAYS = 3 * 24 * 60 * 60

  belongs_to :sketch_file

  scope :recently_modified, -> do
    joins('INNER JOIN sketch_files on sketch_files.id = slices.sketch_file_id')
    .where('sketch_files.last_modified >= ?', Time.now - THREE_DAYS)
    .order('sketch_files.last_modified DESC')
  end
  scope :not_recently_modified, -> do
    joins(:sketch_file)
      .where.not(sketch_files: { last_modified: (Time.now - THREE_DAYS)..Time.now })
  end

  def self.find_by_search(query)
    search_tokens = query.split(/[^\w]/)
    search_tokens.map! { |t| "#{t}*" }

    # TODO: Parameterize this query:
    where('slices MATCH ?', search_tokens.join(' '))
  end
end
