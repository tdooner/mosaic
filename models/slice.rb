class Slice < ActiveRecord::Base
  belongs_to :sketch_file

  after_commit :create_thumbnail

  def create_thumbnail
    full_path = File.expand_path("../../#{path}", __FILE__)
    $logger.info 'Creating thumbnail for ' + full_path
    `convert -thumbnail 300 -crop 300x600 #{full_path} #{full_path.gsub('.png', '.thumb.jpg')}`
  end

  def self.find_by_search(query)
    search_tokens = query.split(/[^\w]/)
    search_tokens.map! { |t| "#{t}*" }

    # TODO: Parameterize this query:
    where('slices MATCH ?', search_tokens.join(' '))
  end
end
