"use strict";
Object.defineProperty(exports, "__esModule", {value: true});
var useTripleSlash;

function parse(source, defs, verbose, tripleSlash) {
  if (tripleSlash === undefined)
    tripleSlash = true;
  useTripleSlash = tripleSlash;
  var lines = source.split('\n');
  for (var n = 0; ;) {
    var startInfo = find_start_if(lines, n);
    if (startInfo === undefined)
      break;
    var endLine = find_end(lines, startInfo.line);
    if (endLine === -1) {
      throw "#if without #endif in line " + (startInfo.line + 1);
    }
    var elseLine = find_else(lines, startInfo.line, endLine);
    var cond = evaluate(startInfo.condition, startInfo.keyword, defs);
    if (cond) {
      if (verbose) {
        console.log("matched condition #" + startInfo.keyword + " " + startInfo.condition + " => including lines [" + (startInfo.line + 1) + "-" + (endLine + 1) + "]");
      }
      blank_code(lines, startInfo.line, startInfo.line);
      if (elseLine === -1) {
        blank_code(lines, endLine, endLine);
      } else {
        blank_code(lines, elseLine, endLine);
      }
    } else {
      if (elseLine === -1) {
        blank_code(lines, startInfo.line, endLine);
      } else {
        blank_code(lines, startInfo.line, elseLine);
        blank_code(lines, endLine, endLine);
      }
      if (verbose) {
        console.log("not matched condition #" + startInfo.keyword + " " + startInfo.condition + " => excluding lines [" + (startInfo.line + 1) + "-" + (endLine + 1) + "]");
      }
    }
    n = startInfo.line;
  }
  return lines.join('\n');
}

exports.parse = parse;

function match_if(line) {
  var re = useTripleSlash ? /^[\s]*\/\/\/([\s]*)#(if)([\s\S]+)$/g : /^[\s]*\/\/([\s]*)#(if)([\s\S]+)$/g;
  var match = re.exec(line);
  if (match) {
    return {
      line: -1,
      keyword: match[2],
      condition: match[3].trim()
    };
  }
  return undefined;
}

function match_endif(line) {
  var re = useTripleSlash ? /^[\s]*\/\/\/([\s]*)#(endif)[\s]*$/g : /^[\s]*\/\/([\s]*)#(endif)[\s]*$/g;
  var match = re.exec(line);
  return Boolean(match);
}

function match_else(line) {
  var re = useTripleSlash ? /^[\s]*\/\/\/([\s]*)#(else)[\s]*$/g : /^[\s]*\/\/([\s]*)#(else)[\s]*$/g;
  var match = re.exec(line);
  return Boolean(match);
}

function find_start_if(lines, n) {
  for (var t = n; t < lines.length; t++) {
    var match = match_if(lines[t]);
    if (match !== undefined) {
      match.line = t;
      return match;
    }
  }
  return undefined;
}

function find_end(lines, start) {
  var level = 1;
  for (var t = start + 1; t < lines.length; t++) {
    var mif = match_if(lines[t]);
    var mend = match_endif(lines[t]);
    if (mif) {
      level++;
    }
    if (mend) {
      level--;
      if (level === 0) {
        return t;
      }
    }
  }
  return -1;
}

function find_else(lines, start, end) {
  var level = 1;
  for (var t = start + 1; t < end; t++) {
    var mif = match_if(lines[t]);
    var melse = match_else(lines[t]);
    var mend = match_endif(lines[t]);
    if (mif) {
      level++;
    }
    if (mend) {
      level--;
    }
    if (melse && level === 1) {
      return t;
    }
  }
  return -1;
}

function evaluate(condition, keyword, defs) {
  var code = "return (" + condition + ") ? true : false;";
  var args = Object.keys(defs);
  var result;
  try {
    var f = new (Function.bind.apply(Function, [void 0].concat(args, [code])))();
    result = f.apply(void 0, args.map(function (k) {
      return defs[k];
    }));
  } catch (error) {
    throw "error evaluation #if condition(" + condition + "): " + error;
  }
  if (keyword === "ifndef") {
    result = !result;
  }
  return result;
}

function blank_code(lines, start, end) {
  for (var t = start; t <= end; t++) {
    var len = lines[t].length;
    var lastChar = lines[t].charAt(len - 1);
    var windowsTermination = lastChar === '\r';
    if (len === 0) {
      lines[t] = '';
    } else if (len === 1) {
      lines[t] = windowsTermination ? '\r' : ' ';
    } else if (len === 2) {
      lines[t] = windowsTermination ? ' \r' : '//';
    } else {
      lines[t] = windowsTermination ? "/".repeat(len - 1) + '\r' : "";
    }
  }
}
