const Mousetrap = require('mousetrap'),
    React = require('react'),
    Router = require('react-router');

const debounce = function(func, wait, immediate) {
  let timeout;
  return function() {
    const context = this, args = arguments;
    const later = function() {
      timeout = null;
      if (!immediate) func.apply(context, args);
    };
    const callNow = immediate && !timeout;
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
    if (callNow) func.apply(context, args);
  };
};

const Header = React.createClass({
  mixins: [Router.Navigation],

  getDefaultProps() {
    return { initialQuery: '' };
  },

  getInitialState() {
    return { query: this.props.initialQuery };
  },

  componentDidMount() {
    this.focusSearch();
    Mousetrap.bind('/', this.focusSearch);
  },

  componentWillUnmount() {
    Mousetrap.unbind('/', this.focusSearch);
  },

  focusSearch() {
    React.findDOMNode(this.refs.mainSearchInput).focus();
  },

  updateFragment: debounce(function() {
    this.transitionTo('/' + React.findDOMNode(this.refs.mainSearchInput).value);
  }, 100),

  updateSearch() {
    this.setState({ query: React.findDOMNode(this.refs.mainSearchInput).value });
    this.updateFragment();
  },

  render() {
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
