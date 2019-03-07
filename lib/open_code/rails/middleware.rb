require 'base64'

module OpenCode
  module Rails
    class Middleware
      cattr_accessor :css
      cattr_accessor :place_holder
      cattr_accessor :root_dir
      cattr_accessor :scheme

      def initialize(app)
        @app = app
      end

      def call(env)
        res = nil
        begin
          res = @app.call(env)
          status, headers, body = res
          return res unless status == 500 && headers['Content-Type'].to_s.include?('html')

          script = <<-JS.strip_heredoc
            (function () {
              setTimeout(function () {
                var prefix = '#{scheme}://file/#{root_dir}';
                var tmp = document.createElement('div');
                var items = document.querySelectorAll('#Application-Trace .trace-frames');
                for (var i = 0; i < items.length; i += 1) {
                  var item = items[i];
                  var frameId = item.dataset.frameId;
                  var uri = encodeURI([prefix, item.innerText.split(':in')[0]].join('/'));
                  var html = '<a href="' + uri + '" class="-gem-open-me-link">#{place_holder}</a>';

                  var links = document.querySelectorAll('[data-frame-id=' + JSON.stringify(frameId) + ']');
                  for (var j = 0; j < links.length; j += 1) {
                    var link = links[j];
                    tmp.innerHTML = html;
                    link.parentElement.insertBefore(tmp.firstChild, link.nextSibling);
                  }
                }
              }, 0);
            })();
          JS

          html = ''
          body.each { |part| html << part }
          html.sub!('</body>', "<style>#{css}</style><script>#{script}</script></body>")
          body = html.encode('utf-8')
          headers['Content-Length'] = body.size
          [status, headers, [body]]
        rescue => e
          ::Rails.logger.error do
            <<-LOG.strip_heredoc
              [OpenCode::Rails::Middleware] #{e.class}: #{e}
                Sorry still something went wrong
                from #{e.backtrace.join("\n  ")}
            LOG
          end
          res
        end
      end
    end
  end
end
