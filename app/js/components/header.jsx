var React = require('react'),
    Router = require('react-router');

var debounce = function(func, wait, immediate) {
  var timeout;
  return function() {
    var context = this, args = arguments;
    var later = function() {
      timeout = null;
      if (!immediate) func.apply(context, args);
    };
    var callNow = immediate && !timeout;
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
    if (callNow) func.apply(context, args);
  };
};

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

  updateFragment: debounce(function() {
    this.transitionTo('/' + React.findDOMNode(this.refs.mainSearchInput).value);
  }, 100),

  updateSearch: function() {
    this.setState({ query: React.findDOMNode(this.refs.mainSearchInput).value });
    this.updateFragment();
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
