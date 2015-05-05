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
webpack app/js/main.jsx -p
wget http://sketchtool.bohemiancoding.com/sketchtool-latest.zip
unzip sketchtool-latest.zip -d vendor

ruby app.rb
```

You will need to go through some more setup steps once you get the application
itself running, but it will walk you through it!
