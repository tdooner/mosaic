const React = require('react'),
    Router = require('react-router'),
    DefaultRoute = Router.DefaultRoute,
    RouteHandler = Router.RouteHandler,
    Route = Router.Route,
    Header = require('./components/header.jsx'),
    Status = require('./components/status.jsx'),
    Search = require('./pages/search.jsx'),
    Homepage = require('./pages/homepage.jsx');

require('./main.css');
require('babel-core/polyfill');

const App = React.createClass({
  contextTypes: {
    router: React.PropTypes.func
  },

  getInitialState() {
    return { initialQuery: this.context.router.getCurrentParams().query };
  },

  render() {
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

const routes = (
  <Route name="app" path="/" handler={App}>
    <Route name="search" path=":query" handler={Search} />

    <DefaultRoute handler={Homepage} />
  </Route>
);

Router.run(routes, function(Handler) {
  React.render(<Handler />, document.body);
});
