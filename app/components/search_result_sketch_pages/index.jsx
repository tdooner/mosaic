const React = require('react');
const SearchResultSketchArtboards = require('search_result_sketch_artboards/index');
const moment = require('moment');

var SearchResultSketchPages = React.createClass({
  propTypes: {
    data: React.PropTypes.object
  },

  render: function() {
    var renderPage = function(a) {
      return (
        <div>
          <p>{a.name}</p>
          <img src={a.thumbnail_path} />
        </div>
      );
    };
    return (<div>{this.props.data['pages'].map(renderPage)}</div>);
    /*
    var result = this.props.result;

    result.basename = result.file.split('/').pop();
    result_info = [];
    result_info.push(
      <span>
        <i className="fa fa-clock-o" />
        {' ' + moment(result.last_modified).fromNow()}
        {' \u00b7 '}
      </span>
    );
    if (result.tags.length > 0) {
      result_info.push(<span>{result.tags.join(',')}</span>);
    }
    result_info.push(<span> <a target='_new' href={'/download/' + result.file_id}>Download from Dropbox</a></span>);

    return (
      <div className="result-file row">
        <div className="result-filename-container">
          <h2 className="result-filename"><i className="fa fa-file-image-o" /> {result.basename}</h2>
          {result_info}
        </div>
        {result.pages.map(function(page) {
        })}
        {result.artboards.map(function(slice) {
          return (<SearchResultSlice slice={slice} />);
        })}
      </div>
    );
    */
  }
});

module.exports = SearchResultSketchPages;