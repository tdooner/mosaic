var React = require('react'),
    $ = require('jquery');

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

module.exports = Status;
