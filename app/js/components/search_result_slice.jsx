const React = require('react'),
    Waypoint = require('react-waypoint');

const SearchResultSlice = React.createClass({
  getInitialState: function() {
    return { showImages: false };
  },

  showImages: function() {
    this.setState({ showImages: true });
  },

  render: function() {
    const slice = this.props.slice;
    const thumb_url = slice.path.replace('.png', '.thumb.jpg'),
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

module.exports = SearchResultSlice;
