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
        next unless ::Rails.env.development? && defined?(::Rails::Server)

        editor = (ENV['FORCE_OPEN_CODE_EDITOR'].presence || cfg.editor).to_s.downcase
        place_holder = ENV['FORCE_OPEN_CODE_PLACE_HOLDER'].presence || cfg.place_holder
        root_dir = ENV['FORCE_OPEN_CODE_ROOT_DIR'].presence || cfg.root_dir

        cfg = config.open_code
        cfg.editor = editor.presence || 'vscode'
        cfg.place_holder = place_holder
        cfg.root_dir = (root_dir.presence || ::Rails.root).to_s.tr('\\', '/').chomp('/')
        next unless Middleware.loadable?(cfg)

        app.middleware.insert_before(ActionDispatch::DebugExceptions, Middleware)
      end
    end
  end
end
