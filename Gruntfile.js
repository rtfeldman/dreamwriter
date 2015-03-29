var fs = require("fs"),
    _  = require("lodash"),
    webpack = require("webpack"),
    webpackConfig = require("./webpack.config.js"),
    awsCredentialsFilename = "aws-credentials.json",
    awsCredentials = fs.existsSync(awsCredentialsFilename) ?
      JSON.parse(fs.readFileSync(awsCredentialsFilename))  : {};

var devWebpackConfig = _.defaults({
    debug: true,
    devtool: "#eval-source-map"
  }, webpackConfig);

/*
  aws-credentials.json should look like this:

  {
    "accessKeyId":     "[access key ID goes here]",
    "secretAccessKey": "[secret access key goes here]",
    "region":          "us-west-2",
    "bucket":          "dreamwriter.io"
  }
*/

module.exports = function(grunt) {
  htmlminFiles = {"dist/index.html": "src/index.html"}

  grunt.initConfig({
    clean: ["dist"],

    watch: {
      elm: {
        files: ["Component/**/*.elm", "Dreamwriter/**/*.elm", "*.elm", "**/*.coffee", "**/*.mustache"],
        tasks: ["webpack:build-dev"]
      },
      stylus: {
        files: ["src/stylesheets/**/*.styl"],
        tasks: ["stylus:dev", "autoprefixer:dev"]
      },
      html: {
        files: ["src/index.html"],
        tasks: ["htmlmin"]
      },
      images: {
        files: ["src/images/*.*"],
        tasks: ["copy:images"]
      },
      fonts: {
        files: ["src/fonts/*.*"],
        tasks: ["copy:fonts"]
      },
      bower: {
        files: ["bower.json"],
        tasks: ["browserifyBower"]
      }
    },

    connect: {
      prod: {
        options: {
          port: 8000,
          base: 'dist',
          keepalive: true
        }
      }
    },

    uglify: {
      prod: {
        options: {
          sourceMap: false
        },
        files: {
          "dist/App.js": "dist/App.js",
          "dist/vendor.js": "dist/vendor.js",
          "dist/bootstrap-elm.js": "dist/bootstrap-elm.js"
        },
      }
    },

    copy: {
      images: {
        expand: true,
        cwd: "src",
        src: "images/**",
        dest: "dist/"
      },
      fonts: {
        expand: true,
        cwd: "src",
        src: "fonts/**",
        dest: "dist/"
      },
      cache: {
        expand: true,
        cwd: "dist",
        src: ["*.*", "fonts/*.*", "images/*.*"],
        dest: "dist/cache/"
      }
    },

    stylus: {
      dev: {
        linenos: true,
        paths: ["src/stylesheets/*.styl"],
        files: {
          "dist/dreamwriter.css": ["src/stylesheets/*.styl"]
        }
      },
      prod: {
        linenos: false,
        paths: "<%= stylus.dev.paths %>",
        files: "<%= stylus.dev.files %>"
      }
    },

    autoprefixer: {
      dev: {
        options: {
          map: true,
          src: "dist/dreamwriter.css",
          dest: "dist/dreamwriter.css"
        },
      },
      prod: {
        options: {
          map: false,
          src: "<%= autoprefixer.dev.src %>",
          dest: "<%= autoprefixer.dev.dest %>"
        }
      }
    },

    webpack: {
      options: webpackConfig,

      "build-prod": {
        debug: false,
        plugins: webpackConfig.plugins.concat(
          new webpack.DefinePlugin({
            "process.env": {
              "NODE_ENV": JSON.stringify("production")
            }
          }),
          new webpack.optimize.DedupePlugin(),
          new webpack.optimize.UglifyJsPlugin()
        )
      },

      "build-dev": {
        devtool: "sourcemap",
        debug: true
      }
    },

    "webpack-dev-server": {
      options: {
        webpack: webpackConfig,
        publicPath: webpackConfig.output.publicPath,
        contentBase: "dist"
      },

      start: {
        keepAlive: true,
        webpack: {
          devtool: "eval",
          debug: true
        }
      }
    },

    htmlmin: {
      options: {
        removeComments: true,
        collapseWhitespace: true
      },
      dev: {
        files: htmlminFiles
      },
      prod: {
        files: htmlminFiles
      }
    },

    cssmin: {
      dev: {
        files: {
          'dist/dreamwriter.css': 'dist/dreamwriter.css'
        }
      },
      prod: {
        files: "<%= cssmin.dev.files %>"
      }
    },

    appcache: {
      options: {
        basePath: 'dist'
      },
      dev: {
        dest: 'dist/dreamwriter.appcache',
        network: '*'
      },
      prod: {
        dest: 'dist/dreamwriter.appcache',
        cache: {
          patterns: ['dist/cache/**/*']
        },
        network: '*',
        fallback: [
          '/                               /cache/index.html',
          '/index.html                     /cache/index.html',
          '/dreamwriter.css                /cache/dreamwriter.css',
          '/App.js                         /cache/App.js',
          '/vendor.js                      /cache/vendor.js',
          '/bootstrap-elm.js               /cache/bootstrap-elm.js',
          '/fonts/ubuntu.woff              /cache/fonts/ubuntu.woff',
          '/fonts/flaticon.woff            /cache/fonts/flaticon.woff',
          '/images/dlogo.png               /cache/images/dlogo.png',
          '/images/favicon.ico             /cache/images/favicon.ico'
        ]
      }
    },

    browserSync: {
      dev: {
        bsFiles: {
          src : 'dist/**/*'
        },
        options: {
          watchTask: true,
          port: 8000,
          server: {
            baseDir: "dist"
          }
        }
      }
    },

    s3: {
      options: awsCredentials,

      deploy: {
        cwd: "dist/",
        src: "**"
      }
    }
  });

  require("matchdep").filterAll("grunt-*").forEach(grunt.loadNpmTasks);

  grunt.registerTask("build:prod", ["stylus:prod", "autoprefixer:prod", "webpack:build-prod", "htmlmin:prod", "copy", "uglify:prod", "cssmin:prod", "appcache:prod"]);
  grunt.registerTask("build:dev",  ["stylus:dev",  "autoprefixer:dev",  "webpack:build-dev",  "htmlmin:dev",  "copy",                               "appcache:dev"]);

  grunt.registerTask("build",  ["build:dev"]);
  grunt.registerTask("prod",   ["build:prod", "connect:prod"]);
  grunt.registerTask("deploy", ["clean", "build:prod", "s3"]);

  grunt.registerTask("default", ["clean", "build", "webpack-dev-server:start", "watch"]);
};