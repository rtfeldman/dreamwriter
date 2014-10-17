module.exports = function(grunt) {
  grunt.initConfig({
    clean: ["dist"],

    watch: {
      elm: {
        files: ["Dreamwriter/**/*.elm", "*.elm"],
        tasks: ["elm"]
      },
      stylus: {
        files: ["src/stylesheets/**/*.styl"],
        tasks: ["stylesheets"]
      },
      html: {
        files: ["src/index.html"],
        tasks: ["copy:index"]
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
      },
      dist: {
        files: ["dist/**/*", "!dist/dreamwriter.appcache", "!dist/cache/**/*"],
        tasks: ["copy:cache", "appcache"]
      }
    },

    connect: {
      "static": {
        options: {
          port: 8000,
          base: 'dist'
        }
      }
    },

    copy: {
      index: {
        src: "src/index.html",
        dest: "dist/index.html"
      },
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
      compile: {
        options: {
          paths: ["src/stylesheets/*.styl"]
        },
        files: {
          "dist/dreamwriter.css": ["src/stylesheets/*.styl"]
        }
      }
    },

    autoprefixer: {
      dreamwriter: {
        options: {
          map: true
        },
        src: "dist/dreamwriter.css",
        dest: "dist/dreamwriter.css"
      }
    },

    elm: {
      dreamwriter: {
        srcDir: "Dreamwriter",
        files: {
          "dist": "App.elm"
        }
      }
    },

    browserify: {
      options: {
        transform: ['browserify-mustache', 'coffeeify'],
        watch: true,
        browserifyOptions: {
          debug: true
        }
      },
      dreamwriter: {
        extensions: ['.coffee', '.mustache', '.json'],
        src: ["./src/**/*.coffee", "./src/**/*.mustache", "./src/**/*.json"],
        dest: "dist/bootstrap-elm.js"
      }
    },

    browserifyBower: {
      options: {
        file: "dist/vendor.js",
        forceResolve: {
          "FileSaver.js": "FileSaver.min.js",
          "db.js": "src/db.js"
        }
      },
      vendor: {}
    },

    appcache: {
      options: {
        basePath: 'dist'
      },
      all: {
        dest: 'dist/dreamwriter.appcache',
        cache: {
          patterns: ['dist/cache/**/*']
        },
        network: '*',
        fallback: [
          '/                               /cache/index.html',
          '/index.html                     /cache/index.html',
          '/dreamwriter.css                /cache/dreamwriter.css',
          '/dreamwriter.css.map            /cache/dreamwriter.css.map',
          '/App.js                         /cache/App.js',
          '/vendor.js                      /cache/vendor.js',
          '/bootstrap-elm.js               /cache/bootstrap-elm.js',
          '/fonts/robot-slab-bold.woff     /cache/fonts/roboto-slab-bold.woff',
          '/fonts/roboto-slab-regular.woff /cache/fonts/roboto-slab-regular.woff',
          '/fonts/ubuntu.woff              /cache/fonts/ubuntu.woff',
          '/images/dlogo.png               /cache/images/dlogo.png',
          '/images/dropbox-logo.png        /cache/images/dropbox-logo.png',
          '/images/favicon.ico             /cache/images/favicon.ico',
          '/images/quarter-backdrop.jpg    /cache/images/quarter-backdrop.jpg']
      }
    }
  });

  ["grunt-contrib-watch", "grunt-contrib-clean", "grunt-elm", "grunt-browserify", "grunt-browserify-bower", "grunt-contrib-copy", "grunt-contrib-connect", "grunt-contrib-stylus", "grunt-autoprefixer", "grunt-appcache"].forEach(function(plugin) {
    grunt.loadNpmTasks(plugin);
  });

  grunt.registerTask("build", ["stylesheets", "browserifyBower", "browserify", "elm", "copy", "appcache"]);
  grunt.registerTask("stylesheets", ["stylus", "autoprefixer"]);

  grunt.registerTask("default", ["clean", "build", "connect", "watch"]);
};