"use strict";
var __assign = (this && this.__assign) || Object.assign || function(t) {
    for (var s, i = 1, n = arguments.length; i < n; i++) {
        s = arguments[i];
        for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
            t[p] = s[p];
    }
    return t;
};
var loaderUtils = require("loader-utils");
var preprocessor_1 = require("./preprocessor");
module.exports = function (source, map) {
    this.cacheable && this.cacheable();
    var options = loaderUtils.getOptions(this);
    var originalData = options.json || options;
    var data = __assign({}, originalData);
    var verboseFlag = "ifdef-verbose";
    var verbose = data[verboseFlag];
    if (verbose !== undefined) {
        delete data[verboseFlag];
    }
    var tripleSlashFlag = "ifdef-triple-slash";
    var tripleSlash = data[tripleSlashFlag];
    if (tripleSlash !== undefined) {
        delete data[tripleSlashFlag];
    }
    try {
        source = preprocessor_1.parse(source, data, verbose, tripleSlash);
        this.callback(null, source, map);
    }
    catch (err) {
        var errorMessage = "ifdef-loader error: " + err;
        this.callback(new Error(errorMessage));
    }
};
