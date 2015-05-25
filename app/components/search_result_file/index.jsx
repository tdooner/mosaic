const React = require('react');
const SearchResultSlice = require('search_result_slice');
const moment = require('moment');

require('./index.css');

const SearchResultFile = React.createClass({
  render() {
    const { result } = this.props;
    const resultBasename = result.file.split('/').pop();

    return (
      <div className="result-file row">
        <div className="result-filename-container">
          <h2 className="result-filename">
            <i className="fa fa-file-image-o" />
            {' '}
            {resultBasename}
          </h2>
          <i className="fa fa-clock-o" />
          {' ' + moment(result.last_modified).fromNow()}
          {' \u00b7 '}
          {(result.tags.length > 0) && result.tags.join(',')}
          <a target='_new' href={`/download/${result.file_id}`}>
            Download from Dropbox
          </a>
        </div>

        {result.slices.map(
          slice => <SearchResultSlice
            key={`${slice.sketch_file_id}${slice.path}${slice.layer}`}
            slice={slice}
          />
        )}
      </div>
    );
  }
});

module.exports = SearchResultFile;
