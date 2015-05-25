var React = require('react'),
    Router = require('react-router'),
    DefaultRoute = Router.DefaultRoute,
    RouteHandler = Router.RouteHandler,
    Route = Router.Route,
    Header = require('./components/header.jsx'),
    Status = require('./components/status.jsx'),
    Search = require('./pages/search.jsx'),
    Homepage = require('./pages/homepage.jsx');

require('babel-core/polyfill');

var App = React.createClass({
  contextTypes: {
    router: React.PropTypes.func
  },

  getInitialState: function() {
    return { initialQuery: this.context.router.getCurrentParams().query };
  },

  render: function() {
    return (
      <div>
        <Header initialQuery={this.state.initialQuery} />
        <div id="search-container-spacer" />
        <div className="container">
          <RouteHandler />
          <Status />
        </div>
      </div>
    );
  }
});

var routes = (
  <Route name="app" path="/" handler={App}>
    <Route name="search" path=":query" handler={Search} />

    <DefaultRoute handler={Homepage} />
  </Route>
);

Router.run(routes, function(Handler) {
  React.render(<Handler />, document.body);
});
