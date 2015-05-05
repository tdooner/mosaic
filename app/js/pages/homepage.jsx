var React = require('react');

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

module.exports = Homepage;
