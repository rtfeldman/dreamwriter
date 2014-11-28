var assert    = require("chai").assert;
var _         = require("lodash");

describe("First page load", function() {
  it("Renders the page container element", function() {
    assert.isDefined(document.getElementById("page"));
  });
});