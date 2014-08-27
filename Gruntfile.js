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
    },

    concat: {
      bower: {
        src: [ 'sandglass/static/bower/normalize-css/normalize.css',
               'sandglass/static/dist/sandglass.css', ],
        dest: 'sandglass/static/dist/sandglass.css',
      }
    }
  });

  require('load-grunt-tasks')(grunt);

  grunt.registerTask( 'build', [ 'bower',
                                 'less',
                                 'concat' ] );
};