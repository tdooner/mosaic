class Slice < ActiveRecord::Base
  belongs_to :sketch_file

  def self.find_by_search(query)
    search_tokens = query.split(/[^\w]/)
    search_tokens.map! { |t| "#{t}*" }

    # TODO: Parameterize this query:
    find_by_sql("SELECT * FROM slices WHERE slices MATCH \"#{search_tokens.join(' ')}\";")
  end
end
