module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    "download-atom-shell": {
      version: "0.15.9",
      outputDir: "./atom-shell",
      rebuild: true
    }
  });

  grunt.loadNpmTasks('grunt-download-atom-shell');

};