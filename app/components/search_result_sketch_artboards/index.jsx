const React = require('react');
const Waypoint = require('react-waypoint');

require('./index.css');

const SearchResultSketchArtboards = React.createClass({
  propTypes: {
    data: React.PropTypes.object
  },

  // getInitialState() {
  //   return { showImages: false };
  // },

  // showImages() {
  //   this.setState({ showImages: true });
  // },

  render() {
    var renderArtboard = function(a) {
      return (
        <div>
          <p>{a.name}</p>
          <img src={a.thumbnail_path} />
        </div>
      );
    };

    return (<div>{this.props.data['artboards'].map(renderArtboard)}</div>);

    /*const slice = this.props.slice;
    const thumb_url = slice.path.replace('.png', '.thumb.jpg');

    return (
      <div className="result-slice col-xs-4">
        <Waypoint onEnter={this.showImages} threshold={0.2} />
        <a href={slice.path} target='_new'>
          <h3>{slice.layer}</h3>
          {this.state.showImages &&
            <img className='result-slice-image' src={thumb_url} />}
        </a>
      </div>
    );
    */
  }
});

module.exports = SearchResultSketchArtboards;
