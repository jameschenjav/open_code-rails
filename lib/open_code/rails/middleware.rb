require 'active_support/all'
require 'pathname'
require 'json'

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

          dir = Pathname.new(__dir__)
          css = dir.join('vcr.css').read
          defaults = generate_defaults(dir, config.editor, config.place_holder, config.root_dir)
          js = dir.join('vcr.js').read.sub('$$__DEFAULTS__$$', JSON.pretty_generate(defaults))
          self.html_code = <<-HTML.strip_heredoc
            <style id="_open-code-rails_">
            #{css}
            </style>
            <script>
            #{js}
            </script>
          HTML
          true
        end

        private

        def generate_defaults(dir, scheme, place_holder, root_dir)
          icon_url = if place_holder.blank?
            require 'base64'
            "data:image/svg+xml;base64,#{Base64.strict_encode64(dir.join('vscode.svg').read)}"
          else
            false
          end

          {
            scheme: scheme,
            rootDir: root_dir,
            placeHolder: place_holder,
            iconUrl: icon_url,
            disabled: false,
          }
        end
      end
    end
  end
end
