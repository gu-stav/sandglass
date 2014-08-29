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

    concat: {
      bower: {
        src: [ 'sandglass/static/bower/normalize-css/normalize.css',
               'sandglass/static/dist/sandglass.css', ],
        dest: 'sandglass/static/dist/sandglass.css',
      }
    },

    watch: {
      less: {
        files: [ 'sandglass/static/less/*.less' ],
        tasks: [ 'less',
                 'concat' ]
      },

      options: {
        spawn: false,
      }
    }
  });

  require('load-grunt-tasks')(grunt);

  grunt.registerTask( 'build', [ 'bower',
                                 'less',
                                 'concat' ] );
};