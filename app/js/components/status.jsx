var React = require('react');

require('../../../node_modules/whatwg-fetch/fetch.js');

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
    fetch('/status').then(function(resp) {
      return resp.json();
    }).then(function(data) {
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

module.exports = Status;
