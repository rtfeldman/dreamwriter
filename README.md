dreamwriter
===============
Streamlined writing software. Written in [Elm](http://elm-lang.org).

## Features

Dreamwriter is a browser-based writing app with a few goals in mind. (Not all of these have been reimplemented yet.)

* Let you edit a 100,000-word novel seamlessly in a single document in the browser.
* Autosave as you write, both to your local device and to remote backups.
* The text in the editor ought to look as close to the final product as possible, without the interference of annotations or other UI elements.
* There should be a logical concept of chapters for navigation and the like, but the document should not be split up into multiple documents to accomplish this.
* You should be able to take notes which accompany the document.
* The app should work completely offline, including being able to bring up the site without an Internet connection.
* It should offer a "distraction-free mode" where by default all you can see on your screen is the text.

## Technology

Dreamwriter was originally written in [CoffeeScript](http://coffee-script.org) and has been rewritten in [Elm](http://elm-lang.org). It compiles to static files only (and requires no server-side code), and [dreamwriter.io](http://dreamwriter.io) is hosted entirely on Amazon S3.

It can only run in modern browsers, as it uses the following browser features:

* [Application Cache](http://caniuse.com/#feat=offline-apps)
* [IndexedDB](http://caniuse.com/#feat=indexeddb)
* [FileReader](http://caniuse.com/#feat=filereader)
* [Blob](http://caniuse.com/#feat=blobbuilder)
* [Fullscreen Mode](http://caniuse.com/#feat=fullscreen)

You can compare the two code bases back when they were at feature parity: [dreamwriter-coffee](https://github.com/rtfeldman/dreamwriter-coffee/tree/strangeloop) and [dreamwriter](https://github.com/rtfeldman/dreamwriter/tree/strangeloop). Naturally, development on the CoffeeScript version has ceased in favor of the more featureful Elm version.

The Strange Loop 2014 talk [Web Apps without Web Servers](http://www.youtube.com/watch?v=WqV5kqaFRDU) incorporated Dreamwriter as a case study.
