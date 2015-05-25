const React = require('react'),
    Router = require('react-router'),
    SearchResultFile = require('../components/search_result_file.jsx');

require('../../../node_modules/whatwg-fetch/fetch.js');

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
    return (
      <div>
        {this.state.results.map(result =>
          <SearchResultFile result={result} key={result.file_id} />)}
      </div>
    );
  }
});

module.exports = Search;
