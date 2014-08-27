var coffeescript = require('coffee-script').register();

Sandglass = require( './sandglass/app.coffee' );

new Sandglass()
  .start()
  .then(function( sandglass ) {
    if( !sandglass.migrations ) {
      return
    }

    sandglass.migrate( 'gustavpursche@gmail.com',
                       'test',
                       '/Users/gustavpursche/Desktop/hamster.db' )
  });