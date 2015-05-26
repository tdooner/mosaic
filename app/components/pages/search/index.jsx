const React = require('react');
const Router = require('react-router');
const SearchResultSketchArtboards = require('search_result_sketch_artboards');
const SearchResultSketchPages = require('search_result_sketch_pages');

require('whatwg-fetch');

const Search = React.createClass({
  contextTypes: {
    router: React.PropTypes.func
  },

  getInitialState() {
    return { query: this.context.router.getCurrentParams().query, results: [] };
  },

  componentWillMount() {
    this.performSearch();
  },

  componentWillReceiveProps() {
    const query = this.context.router.getCurrentParams().query;
    this.setState({ query: query });
    this.performSearch();
  },

  shouldComponentUpdate(nextProps, nextState) {
    return nextState.resultsForQuery === this.context.router.getCurrentParams().query;
  },

  performSearch() {
    const query = this.context.router.getCurrentParams().query;
    const body = new FormData();
    body.append("query", query);

    fetch('/search', { method: 'POST', body: body })
      .then(resp => resp.json())
      .then((data) => {
        this.setState({
          results: data.results,
          resultsForQuery: data.search
        });
      });
  },

  render() {
    var resultTypeToClass = {
      'sketch_pages': SearchResultSketchPages,
      'sketch_artboards': SearchResultSketchArtboards
    };

    var renderResult = function(result) {
      var basename = result['file']['dropbox_path'].split('/').pop();
      return (
        <div className="result-file row">
          <div className="result-filename-container">
            <h2 className="result-filename" title={result['file']['dropbox_path']}>
              <i className="fa fa-file-image-o" />{' '}{basename}
            </h2>
          </div>
          {React.createElement(resultTypeToClass[result['result_type']], { data: result['data'] })}
        </div>
      );
    }

    return (
      <div>
        {this.state.results.map(renderResult)}
      </div>
    );
  }
});

module.exports = Search;
