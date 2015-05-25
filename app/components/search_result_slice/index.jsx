const React = require('react');
const Waypoint = require('react-waypoint');

const SearchResultSlice = React.createClass({
  getInitialState() {
    return { showImages: false };
  },

  showImages() {
    this.setState({ showImages: true });
  },

  render() {
    const slice = this.props.slice;
    const thumb_url = slice.path.replace('.png', '.thumb.jpg');

    return (
      <div className="result-slice col-xs-4">
        <Waypoint onEnter={this.showImages} threshold={0.2} />
        <a href={slice.path} target='_new'>
          <h3 className='result-slice-layer-title'>{slice.layer}</h3>
          {this.state.showImages &&
            <img className='result-slice-image' src={thumb_url} />}
        </a>
      </div>
    );
  }
});

module.exports = SearchResultSlice;
