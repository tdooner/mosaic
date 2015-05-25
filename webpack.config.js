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
      }
    ]
  }
};
