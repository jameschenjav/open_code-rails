require 'active_support/all'

module OpenCode
  module Rails
    class Middleware
      cattr_accessor :html_code

      def initialize(app)
        @app = app
      end

      def call(env)
        res = @app.call(env)
        begin
          status, headers, body = res
          return res unless status.to_s == '500' && headers['Content-Type'].to_s.include?('html')

          html = ''
          body.each { |part| html << part }
          body = html.sub('</body>', "#{html_code}</body>").encode('utf-8')
          headers['Content-Length'] = body.size
          [status, headers, [body]]
        rescue => e
          ::Rails.try(:logger)&.error do
            <<-LOG.strip_heredoc
              [OpenCode::Rails::Middleware] #{e.class}: #{e}
                Sorry still something went wrong
                from #{e.backtrace.join("\n  ")}
            LOG
          end
          res
        end
      end

      class << self
        def loadable?(config)
          return false if %w[false off disabled].include?(config.editor)

          css = generate_css(config.place_holder.blank?)
          js = generate_js(config.editor, config.place_holder, config.root_dir)
          self.html_code = "<style>#{css}</style><script>#{js}</script>"
          true
        end

        private

        def generate_js(scheme, place_holder, root_dir)
          <<-JS.strip_heredoc
            (function () {
              setTimeout(function () {
                var prefix = '#{scheme}://file/#{root_dir}';
                var tmp = document.createElement('div');
                var items = document.querySelectorAll('#Application-Trace .trace-frames');
                for (var i = 0; i < items.length; i += 1) {
                  var item = items[i];
                  var uri = [prefix, item.innerText.split(':in')[0]].join('/');
                  var h = JSON.stringify(encodeURI(uri));
                  var html = '<a href=' + h + ' class="open-code-rails-link">#{place_holder}</a>';

                  var selFrameId = JSON.stringify(item.dataset.frameId);
                  var links = document.querySelectorAll('[data-frame-id=' + selFrameId + ']');
                  for (var j = 0; j < links.length; j += 1) {
                    var link = links[j];
                    tmp.innerHTML = html;
                    link.parentElement.insertBefore(tmp.firstChild, link.nextSibling);
                  }
                }
              }, 0);
            })();
          JS
        end

        def generate_css(use_icon)
          css = <<-CSS.strip_heredoc
            .open-code-rails-link {
              box-sizing: border-box;
              display: inline-block;
              margin-left: 8px;
              padding: 1px 6px;
              vertical-align: middle;
              border: 1px solid #FFCCCB;
              color: #C52E23;
              border-radius: 4px;
              text-decoration: none;
            }
            .open-code-rails-link:hover {
              border-color: #C52E23;
            }
          CSS
          return css unless use_icon

          require 'pathname'
          require 'base64'
          icon = Base64.strict_encode64(Pathname.new(__dir__).join('vscode.svg').read)

          css << <<-CSS.strip_heredoc
            .open-code-rails-link {
              padding: 3px;
            }
            .open-code-rails-link::after {
              display: block;
              content: '';
              width: 12px;
              height: 12px;
              background-image: url('data:image/svg+xml;base64,#{icon}');
            }
          CSS
          css
        end
      end
    end
  end
end
