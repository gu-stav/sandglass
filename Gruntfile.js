module.exports = function(grunt) {
  grunt.initConfig({
    coffee: {
      compile: {
        expand: true,
        src: [ '**/*.coffee' ],
        ext: '.js'
      }
    },

    watch: {
      coffee: {
        files: 'sandglass/**/*.coffee',
        tasks: [ 'coffee' ],
      },
    },


  });

  require('load-grunt-tasks')(grunt);

  grunt.registerTask( 'default', [ 'coffee' ] );
};