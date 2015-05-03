var Router = ReactRouter,
    Route = Router.Route,
    DefaultRoute = Router.DefaultRoute,
    RouteHandler = Router.RouteHandler;

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
    this.setState({ query: e.target.value });
    this.transitionTo('/' + e.target.value);
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

var Homepage = React.createClass({
  render: function() {
    return (
      <div className="row" id="no-results">
        <div className="col-xs-12">
          <h2>Welcome to Mosaic</h2>
          <span style={{fontSize: '96px'}}>
            <i className="fa fa-diamond" style={{color: '#ecb22f'}} />
            {' '}
            <i className="fa fa-arrow-right" style={{opacity: '0.2'}} />
            {' '}
            <i className="fa fa-dropbox" style={{color: '#3277e3'}} />
            {' '}
            <i className="fa fa-arrow-right" style={{opacity: '0.2'}} />
            {' '}
            <i className="fa fa-thumbs-o-up" style={{color: '#009900'}} />
          </span>

          <h3>How it works:</h3>
          <p>
            Every <b>.sketch</b> file in the Design dropbox is being watched.
            When an update happens, this app will fetch the new version and
            export all the slices into separate PNGs.
          </p>
          <p>
            All PNGs are searchable by name, with the link back to the original
            design file in Dropbox.
          </p>

          <h3>Try some search queries:</h3>
          <ul>
            <li>"partner tools"</li>
            <li>"ribbon"</li>
            <li>"profile android"</li>
            <li>"support button"</li>
            <li>"delight card"</li>
          </ul>
        </div>
      </div>
    );
  }
});

var Status = React.createClass({
  getInitialState: function() {
    return { inSync: undefined, totalSlices: undefined };
  },

  componentWillMount: function() {
    this.updateCounter();
  },

  componentWillUnmount: function() {
    if (this.updateJob) {
      window.clearTimeout(this.updateJob);
    }
  },

  updateCounter: function() {
    $.getJSON('/status', {}, function(data, textStatus, xhr) {
      this.setState({ inSync: data.in_sync, totalSlices: data.files });

      if (data.in_sync != data.files) {
        this.updateJob = window.setTimeout(this.updateCounter, 2000);
      }
    }.bind(this));
  },

  render: function() {
    return (
      <div className="row">
        <div className="col-xs-12">
          <p id="status-container">
            Status:
            {' '}
            <span id="status">
              <b>{this.state.inSync}</b> files in sync (of <b>{this.state.totalSlices}</b>)
            </span>
          </p>
        </div>
      </div>
    );
  }
});

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

var SearchResultSlice = React.createClass({
  getInitialState: function() {
    return { showImages: false };
  },

  showImages: function() {
    this.setState({ showImages: true });
  },

  render: function() {
    var slice = this.props.slice;
    var thumb_url = slice.path.replace('.png', '.thumb.jpg'),
        image_attr = this.state.showImages ? { "src" : thumb_url } : { "data-original": thumb_url };

    return (
      <div className="result-slice col-xs-4">
        <Waypoint onEnter={this.showImages} threshold={0.2} />
        <a href={slice.path} target='_new'>
          <h3 className='result-slice-layer-title'>{slice.layer}</h3>
          {React.DOM.img(image_attr)}
        </a>
      </div>
    );
  }
});

var SearchResultFile = React.createClass({
  render: function() {
    var result = this.props.result;

    result.basename = result.file.split('/').pop();
    result_info = [];
    result_info.push(
      <span>
        <i className="fa fa-clock-o" />
        {' ' + new Date(result.last_modified).toRelativeTime()}
        {' \u00b7 '}
      </span>
    );
    if (result.tags.length > 0) {
      result_info.push(<span>{result.tags.join(',')}</span>);
    }
    result_info.push(<span><a target='_new' href={'/download/' + result.file_id}>Download from Dropbox</a></span>);

    return (
      <div className="result-file row">
        <div className="result-filename-container">
          <h2 className="result-filename"><i className="fa fa-file-image-o" /> {result.basename}</h2>
          {result_info}
        </div>
        {result.slices.map(function(slice) {
          return <SearchResultSlice slice={slice} />
        })}
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
