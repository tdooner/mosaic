const Mousetrap = require('mousetrap');
const React = require('react');
const Router = require('react-router');

require('./index.css');

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
      <div className="header">
        <div className="search-container">
          <label className="search-icon" htmlFor="search-input">
            <i className="fa fa-search" />
          </label>
          <input
            autoComplete="off"
            autoFocus
            className="search-input"
            id="search-input"
            onChange={this.updateSearch}
            ref="mainSearchInput"
            type="search"
            value={this.state.query}
          />
        </div>
      </div>
    );
  }
});

module.exports = Header;
