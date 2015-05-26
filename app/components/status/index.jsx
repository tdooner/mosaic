const React = require('react');

require('whatwg-fetch');

const Status = React.createClass({
  getInitialState() {
    return { inSync: undefined, totalSlices: undefined };
  },

  componentWillMount() {
    this.updateCounter();
  },

  componentWillUnmount() {
    if (this.updateJob) {
      window.clearTimeout(this.updateJob);
    }
  },

  updateCounter() {
    fetch('/status').then(resp => resp.json()).then(data => {
      this.setState({
        inSync: data.in_sync,
        totalSlices: data.files,
      });

      if (data.in_sync != data.files) {
        this.updateJob = window.setTimeout(this.updateCounter, 2000);
      }
    });
  },

  render() {
    return (
      <div className="row">
        <div className="col-xs-12">
          <p>
            Status:
            {' '}
            <span>
              <b>{this.state.inSync}</b> files in sync
              (of <b>{this.state.totalSlices}</b>)
            </span>
          </p>
        </div>
      </div>
    );
  }
});

module.exports = Status;
