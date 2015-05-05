module.exports = {
  output: {
    filename: 'build/application.js'
  },
  module: {
    loaders: [
      { test: /\.jsx$/, loader: 'jsx-loader' }
    ]
  }
}
