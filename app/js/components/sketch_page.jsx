var React = require('react');

var SketchPage = React.createClass({
  getOriginalCoords: function(e) {
    // bounds:  0     1     2       3
    //         left, top, right, bottom
    // cache this?
    var bounds = this.props.originalBounds.split(',').map(parseFloat);

    var clickX = (e.clientX + window.scrollX);
    var clickY = (e.clientY + window.scrollY);

    var img = React.findDOMNode(this.refs.fullImage)
    var heightFactor = (bounds[3] - bounds[1]) / img.height,
        widthFactor = (bounds[2] - bounds[0]) / img.width;

    return {
      "mouseLeft": bounds[0] + (clickX - img.offsetLeft) * widthFactor,
      "mouseTop": bounds[1] + (clickY - img.offsetTop) * heightFactor
    };
  },

  handleMouseMove: function(e) {
    this.setState(this.getOriginalCoords(e));
  },

  handleClick: function(e) {
    var coords = this.getOriginalCoords(e);

    for (i in this.props.artboards) {
      var artboard = this.props.artboards[i].split(","),
          left = parseInt(artboard[1]),
          top = parseInt(artboard[2]),
          right = parseInt(artboard[3]),
          bottom = parseInt(artboard[4]);
  
      if (left < coords['mouseLeft'] && coords['mouseLeft'] < right &&
          top < coords['mouseTop'] && coords['mouseTop'] < bottom) {
        this.setState({foundArtboard: artboard[0]});
        return;
      }
    }
  },

  getInitialState: function() {
    return { foundArtboard: '', mouseLeft: 0, mouseTop: 0 };
  },

  componentDidMount: function() {
    var image = React.findDOMNode(this.refs.fullImage)

    image.addEventListener('mousemove', this.handleMouseMove);
    image.addEventListener('click', this.handleClick);
  },

  render: function() {
    var imgStyle = {width: '100%'};

    return (
      <div>
        <img
          ref="fullImage"
          src={this.props.fullImageSrc}
          style={imgStyle}
        />
        <img src={"/ftuflow/slices/" + this.state.foundArtboard + '.png'} />
      </div>
    );
  }
});

module.exports = SketchPage;
