module.exports = function(grunt) {
  grunt.initConfig({
    less: {
      dist: {
        files: {
          'sandglass/static/dist/sandglass.css':
          'sandglass/static/less/sandglass.less'
        }
      },
    }
  });

  require('load-grunt-tasks')(grunt);

  grunt.registerTask( 'build', [ 'less' ] );
};