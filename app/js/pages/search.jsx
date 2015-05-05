var React = require('react'),
    Router = require('react-router'),
    SearchResultFile = require('../components/search_result_file.jsx'),
    $ = require('jquery');

var Search = React.createClass({
  contextTypes: {
    router: React.PropTypes.func
  },

  getInitialState: function() {
    return { query: this.context.router.getCurrentParams().query, results: [] };
  },

  componentWillMount: function() {
    this.performSearch();
  },

  componentWillReceiveProps: function() {
    var query = this.context.router.getCurrentParams().query;
    this.setState({ query: query });
    this.performSearch();
  },

  performSearch: function() {
    var query = this.context.router.getCurrentParams().query;

    $.post('/search', {
      query: query
    }, function(data, status, xhr) {
      this.setState({ results: data.results });
    }.bind(this));
  },

  render: function() {
    return (
      <div>
        {this.state.results.map(function(result, i) {
          return <SearchResultFile result={result} key={i} />;
        })}
      </div>
    );
  }
});

module.exports = Search;
