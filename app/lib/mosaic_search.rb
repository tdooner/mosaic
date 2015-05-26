class MosaicSearch
  def initialize(query)
    @query = query
  end

  def results
    search_tokens = tokenize_query
    searchers = [
      MosaicSearch::SketchPageResult,
      MosaicSearch::SketchArtboardResult,
    ].map { |klass| klass.new(search_tokens) }

    searchers.each(&:find_candidates)
    searchers.each(&:group_candidates)
    searchers.each(&:score_candidates)

    searchers.each_with_object([]) do |searcher, results|
      results.concat(Array(searcher.results))
    end
  end

  class BaseSearcher
    attr_reader :results

    def initialize(search_tokens)
      @search_tokens = search_tokens
      @results = []
    end

    def add_result(type, file, score, data)
      # TODO: Improve this format for frontend consumption
      # TODO: Improve score thing
      @results << [type, file, data]
    end
  end

  private

  def tokenize_query
    @query.split(/[^\w]/).map { |t| "#{t}*" }
  end

  def compute_results(search_tokens)
  end
end
