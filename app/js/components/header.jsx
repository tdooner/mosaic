var React = require('react'),
    Router = require('react-router');

var Header = React.createClass({
  mixins: [Router.Navigation],

  getDefaultProps: function() {
    return { initialQuery: '' };
  },

  getInitialState: function() {
    return { query: this.props.initialQuery };
  },

  componentDidMount: function() {
    React.findDOMNode(this.refs.mainSearchInput).focus();
  },

  updateSearch: function(e) {
    this.setState({ query: React.findDOMNode(this.refs.mainSearchInput).value });
    setTimeout(function() {
      this.transitionTo('/' + React.findDOMNode(this.refs.mainSearchInput).value);
    }.bind(this), 1);
  },

  render: function() {
    return (
      <div key={1} className="sticky-header search-mode" id="search-container">
        <div className="container">
          <div className="row">
            <i className="fa fa-search search-icon" />
            <span className="search-or-filename">
              <input
                ref="mainSearchInput"
                value={this.state.query}
                onChange={this.updateSearch}
                id="search"
                autoComplete="off" />
              <span id="filename" />
            </span>
          </div>
        </div>
      </div>
    );
  }
});

module.exports = Header;
