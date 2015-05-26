const React = require('react');
const Router = require('react-router');
const DefaultRoute = Router.DefaultRoute;
const RouteHandler = Router.RouteHandler;
const Route = Router.Route;
const Header = require('header');
const Status = require('status');
const Search = require('pages/search');
const Homepage = require('pages/homepage');
const SketchPagePage = require('pages/sketch_page/index');

require('./index.css');
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
    <Route name="sketchPage" path="page/:id" handler={SketchPagePage} />

    <DefaultRoute handler={Homepage} />
  </Route>
);

Router.run(routes, function(Handler) {
  React.render(<Handler />, document.body);
});

