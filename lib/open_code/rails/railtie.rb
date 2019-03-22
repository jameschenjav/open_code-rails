require "rails/railtie"

module OpenCode
  module Rails
    class Railtie < ::Rails::Railtie
      config.open_code = ActiveSupport::OrderedOptions.new
      config.open_code.editor = 'vscode'
      config.open_code.logger_url = false

      initializer "open_code.initialize" do
        abort('open_code-rails should not be used in production mode!') if ::Rails.env.production?
      end

      initializer "open_code.insert_middleware" do |app|
        next unless ::Rails.env.development? && defined?(::Rails::Server)

        cfg = config.open_code
        editor = (ENV['FORCE_OPEN_CODE_EDITOR'].presence || cfg.editor).to_s.downcase
        place_holder = ENV['FORCE_OPEN_CODE_PLACE_HOLDER'].presence || cfg.place_holder
        root_dir = ENV['FORCE_OPEN_CODE_ROOT_DIR'].presence || cfg.root_dir

        cfg.editor = editor.presence || 'vscode'
        cfg.place_holder = place_holder
        cfg.root_dir = (root_dir.presence || ::Rails.root).to_s.tr('\\', '/').chomp('/')
        next unless Middleware.loadable?(cfg)

        app.middleware.insert_before(ActionDispatch::DebugExceptions, Middleware)

        logger_url = ENV['FORCE_OPEN_CODE_LOGGER_URL']
        logger_url = if logger_url.blank?
          cfg.logger_url
        else
          !%w[OFF FALSE DISABLED].include?(logger_url.upcase)
        end
        next unless logger_url

        scheme = cfg.editor
        root_dir = cfg.root_dir

        bc = ::Rails.backtrace_cleaner
        bc.class_eval { alias_method :vcr_clean, :clean }
        bc.define_singleton_method(:clean) do |*args|
          vcr_clean(*args).map do |ln|
            begin
              next ln unless ln =~ %r(^\w+\/.+?:in)
              " #{scheme}://file/#{root_dir}/#{ln.split(':in').join(' in')}"
            rescue => _e
              ln
            end
          end
        end
      end
    end
  end
end
