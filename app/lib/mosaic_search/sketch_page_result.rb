require_relative '../mosaic_search.rb'

class MosaicSearch
  class SketchPageResult < BaseSearcher
    def find_candidates
      @candidates = 
        SketchPage.
          joins('JOIN pages_fts ON pages_fts.page_id = sketch_pages.id').
          where('pages_fts.body MATCH ?', @search_tokens)

    end

    def group_candidates
      @candidates = @candidates.includes(:sketch_file).group_by(&:sketch_file)
    end

    def score_candidates
      @candidates.each do |file, pages|
        add_result(:sketch_page, file, 3 * pages.count, { pages: pages })
      end
    end
  end
end
