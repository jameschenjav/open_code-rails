(function () {
  var CSS_ICON_POS = '/* _ICON_ */';
  var defaults = $$__DEFAULTS__$$;

  defaults.linkBuilder = function (scheme, rootDir, path, line) {
    return scheme + '://file/' + encodeURI(rootDir + '/' + path + ':' + line);
  };

  var current = {
    scheme: defaults.scheme,
    rootDir: defaults.rootDir,
    linkBuilder: defaults.linkBuilder,
    placeHolder: defaults.placeHolder,
    iconUrl: defaults.iconUrl,
    disabled: false
  };

  function generateIconStyle() {
    return current.placeHolder || !current.iconUrl ? null :
      '.open-code-rails-link {' +
      '  padding: 3px;' +
      '}' +
      '.open-code-rails-link::after {' +
      '  display: block;' +
      '  content: "";' +
      '  width: 12px;' +
      '  height: 12px;' +
      '  background-image: url(' + JSON.stringify(current.iconUrl) + ');' +
      '}';
  }

  function buildLink(path, line) {
    return current.linkBuilder(current.scheme, current.rootDir, path, line);
  }

  var cssStyle = null;

  function removeLoggerUri() {
    var items = document.querySelectorAll('#Application-Trace .trace-frames, #Full-Trace .trace-frames');
    var rootPath = defaults.rootDir + '/';
    for (var i = 0; i < items.length; i += 1) {
      var item = items[i];
      var line = item.innerText;
      if (line.indexOf(rootPath) < 0) continue;

      var parts = line.split(rootPath);
      item.innerText = parts[parts.length - 1];
    }
  }

  function generateLinks() {
    if (cssStyle == null) {
      cssStyle = document.querySelector('style#_open-code-rails_') || false;
      if (cssStyle) {
        cssStyle.innerText = cssStyle.innerText + CSS_ICON_POS;
      }
    }

    if (current.disabled) return;

    var iconStyle = generateIconStyle();
    if (iconStyle && cssStyle) {
      cssStyle.innerText = cssStyle.innerText + iconStyle;
    }
    var tmp = document.createElement('div');
    var items = document.querySelectorAll('#Application-Trace .trace-frames');
    var ph = current.placeHolder || '';
    for (var i = 0; i < items.length; i += 1) {
      var item = items[i];
      var pathLine = item.innerText.split(/:(\d+)/, 2);
      var h = JSON.stringify(buildLink(pathLine[0], pathLine[1]));
      var html = '<a href=' + h + ' class="open-code-rails-link">' + ph + '</a>';

      var selFrameId = JSON.stringify(item.dataset.frameId);
      var links = document.querySelectorAll('[data-frame-id=' + selFrameId + ']');
      for (var j = 0; j < links.length; j += 1) {
        var link = links[j];
        tmp.innerHTML = html;
        link.parentElement.insertBefore(tmp.firstChild, link.nextSibling);
      }
    }
  }

  setTimeout(function () {
    removeLoggerUri();
    generateLinks();
  }, 0);
  if (!window.localStorage) return;

  var ROOT_KEY = '_dbg-open_code_';
  function loadLocalSettings() {
    try {
      var settings = JSON.parse(localStorage.getItem(ROOT_KEY) || '{}') || {};
      var linkBuilder = settings.linkBuilder;
      delete settings.linkBuilder;
      for (var key in defaults) {
        current[key] = settings[key];
      }
      try {
        current.linkBuilder = linkBuilder && eval(linkBuilder);
      } catch (_e) {
        current.linkBuilder = null;
      }
    } catch (_e) {}

    for (var key in defaults) {
      if (current[key] != null) continue;
      current[key] = defaults[key];
    }
  }

  loadLocalSettings();

  function regenerate() {
    var links = document.querySelectorAll('.open-code-rails-link');
    for (var j = 0; j < links.length; j += 1) {
      var link = links[j];
      link.parentElement.removeChild(link);
    }

    if (cssStyle) {
      var css = cssStyle.innerText;
      var pos = css.indexOf(CSS_ICON_POS);
      cssStyle.innerText = css.slice(0, pos) + CSS_ICON_POS;
    }

    loadLocalSettings();
    generateLinks();
  }

  function check(key) {
    if (typeof defaults[key] == 'undefined') throw Error('Unsupported key: ' + key);
  }

  var ocr = {
    settings: function () {
      var r = {};
      for (var key in defaults) {
        var val = current[key]
        r[key] = val == null ? defaults[key] : val;
      }
      if (r.placeHolder) r.iconUrl = null;
      return r;
    },
    getValue: function (key) {
      check(key);
      return (ocr.settings() || {})[key];
    },
    setValue: function(key, value) {
      check(key);
      var settings = ocr.settings();
      var oldVal = key == 'linkBuilder' ? settings[key].toString() : settings[key];
      var val = key == 'linkBuilder' && typeof value == 'function' ? value.toString() : value;
      if (oldVal == val) return;

      settings[key] = val;
      if (key == 'placeHolder' && value || key == 'iconUrl' && !value) {
        settings.iconUrl = null;
      } else if (key == 'iconUrl' && value || key == 'placeHolder' && !value) {
        settings.placeHolder = null;
      }

      var json = {};
      for (var k in settings) {
        var v = settings[k];
        if (v == null || '' + v == '' + defaults[k]) continue;
        json[k] = v;
      }
      localStorage.setItem(ROOT_KEY, JSON.stringify(json));
      regenerate();
      return settings[key];
    },
    reset() {
      localStorage.removeItem(ROOT_KEY);
      regenerate();
    }
  };
  window._openCode = ocr;
})();
