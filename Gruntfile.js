module.exports = function(grunt) {
  grunt.initConfig({
    less: {
      dist: {
        files: {
          'sandglass/static/dist/sandglass.css':
          'sandglass/static/less/sandglass.less'
        }
      },
    },

    bower: {
      dist: {
        options: {
          targetDir: 'sandglass/static/bower/',
          cleanBowerDir: true,
          verbose: true,
        }
      }
    }
  });

  require('load-grunt-tasks')(grunt);

  grunt.registerTask( 'build', [ 'bower',
                                 'less' ] );
};