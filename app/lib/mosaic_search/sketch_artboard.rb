require_relative '../mosaic_search.rb'

class MosaicSearch
  class SketchArtboardResult < BaseSearcher
    def find_candidates
      @candidates =
        SketchArtboard.
          joins('JOIN artboards_fts ON artboards_fts.artboard_id = sketch_artboards.id').
          where('artboards_fts.body MATCH ?', @search_tokens)
    end

    def group_candidates
      @candidates = @candidates
        .includes(sketch_page: :sketch_file)
        .group_by { |c| c.sketch_page.sketch_file }
    end

    def score_candidates
      @candidates.each do |file, artboards|
        score = artboards.count
        add_result(:sketch_artboard, file, score, { artboards: artboards })
      end
    end
  end
end
