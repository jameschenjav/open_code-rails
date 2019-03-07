require "rails/railtie"

module OpenCode
  module Rails
    class Railtie < ::Rails::Railtie
      config.open_code = ActiveSupport::OrderedOptions.new
      config.open_code.editor = 'vscode'

      initializer "open_code.initialize" do
        abort('open_code-rails should not be used in production mode!') if ::Rails.env.production?
      end

      initializer "open_code.insert_middleware" do |app|
        next if ::Rails.env.production? || !defined?(::Rails::Server)

        require 'open_code/rails/const_assets'
        require 'open_code/rails/middleware'

        css = <<-CSS.strip_heredoc
          .-gem-open-me-link {
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
          .-gem-open-me-link:hover {
            border-color: #C52E23;
          }
        CSS

        cfg = config.open_code
        if cfg.place_holder.blank?
          b64 = Base64.strict_encode64(ConstAssets::ICONS[:vscode])
          css << <<-CSS.strip_heredoc
            .-gem-open-me-link {
              padding: 3px;
            }
            .-gem-open-me-link::after {
              display: block;
              content: '';
              width: 12px;
              height: 12px;
              background-image: url('data:image/svg+xml;base64,#{b64}');
            }
          CSS
        end

        Middleware.css = css.freeze
        Middleware.place_holder = cfg.place_holder
        Middleware.root_dir = (cfg.root_dir.presence || ::Rails.root).to_s.tr('\\', '/').chomp('/')
        Middleware.scheme = cfg.editor.presence || 'vscode'
        app.middleware.insert_before(ActionDispatch::DebugExceptions, Middleware)
      end
    end
  end
end
