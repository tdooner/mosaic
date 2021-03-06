const autoprefixer = require('autoprefixer-core');

module.exports = {
  output: {
    filename: 'build/application.js'
  },
  module: {
    loaders: [
      {
        test: /\.jsx?$/,
        loader: 'babel-loader?cacheDirectory=true',
        exclude: [/node_modules/]
      },
      {
        test: /\.css$/,
        loader: 'style-loader!css-loader!postcss-loader'
      }
    ]
  },
  postcss: [autoprefixer],
  resolve: {
    modulesDirectories: [
      'app/components',
      'node_modules'
    ],
    extensions: ['', '.js', '.jsx']
  }
};
