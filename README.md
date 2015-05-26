Mosaic
=================================================================

Mosaic helps you find designs. It only runs on Mac OS.

## Setup Instructions

```
brew install npm imagemagick --build-from-source
sudo yum install sqlite-devel
git clone -o upstream https://github.com/tdooner/mosaic.git
cd mosaic
npm install
$(npm bin)/webpack app/components -p
wget http://sketchtool.bohemiancoding.com/sketchtool-latest.zip
unzip sketchtool-latest.zip -d vendor && rm sketchtool-latest.zip
bundle install

bundle exec ruby app.rb
```

You will need to go through some more setup steps (e.g. setting up a Dropbox
app) once you get the application itself running, but it will walk you through
it!

Once you have everything set up, you can access the Mosaic server locally at
`http://localhost:4567`.


## Development Instructions
- use `$(npm bin)/webpack app/components --watch` instead
