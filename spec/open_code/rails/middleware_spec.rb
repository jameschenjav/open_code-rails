module OpenCode
  module Rails
    RSpec.describe(Middleware) do
      before :each do
        @config = ActiveSupport::OrderedOptions.new
        @config.editor = 'vscode'
        @config.place_holder = ''
        @config.root_dir = __dir__
      end

      describe 'Can be disabled' do
        it 'is enabled by default' do
          expect(Middleware.loadable?(@config)).to be true
        end

        it 'is disabled when set config.editor to false' do
          @config.editor = 'false'
          expect(Middleware.loadable?(@config)).to be false
        end

        it 'is disabled when set config.editor to off' do
          @config.editor = 'off'
          expect(Middleware.loadable?(@config)).to be false
        end

        it 'is disabled when set config.editor to disabled' do
          @config.editor = 'disabled'
          expect(Middleware.loadable?(@config)).to be false
        end
      end

      describe 'Can generate correct HTML code' do
        it 'uses vscode and icon by default' do
          expect(Middleware.loadable?(@config)).to be true
          lines = Middleware.html_code.split("\n").map(&:strip)

          prefix = lines.find { |ln| ln =~ /^var\s*prefix/ }
          prefix = prefix.match(/prefix\s*=\s*'(.+?)';$/)[1]
          place_holder = lines.find { |ln| ln =~ /<a href=.+?open-code-rails-link/ }
          place_holder = place_holder.match(/open-code-rails-link">(.*?)<\/a>';$/)[1]

          expect(prefix.starts_with?("vscode://")).to be true
          expect(lines.find { |ln| ln =~ /\.open-code-rails-link::after/ }).to be_truthy
          expect(place_holder).to be_blank
          expect(prefix.ends_with?(@config.root_dir)).to be true
        end

        it 'uses vscodium and icon when set config.editor to vscodium' do
          @config.editor = 'vscodium'
          expect(Middleware.loadable?(@config)).to be true
          lines = Middleware.html_code.split("\n").map(&:strip)

          prefix = lines.find { |ln| ln =~ /^var\s*prefix/ }
          prefix = prefix.match(/prefix\s*=\s*'(.+?)';$/)[1]
          place_holder = lines.find { |ln| ln =~ /<a href=.+?open-code-rails-link/ }
          place_holder = place_holder.match(/open-code-rails-link">(.*?)<\/a>';$/)[1]

          expect(prefix.starts_with?("vscodium://")).to be true
          expect(lines.find { |ln| ln =~ /\.open-code-rails-link::after/ }).to be_truthy
          expect(place_holder).to be_blank
          expect(prefix.ends_with?(@config.root_dir)).to be true
        end

        it 'uses vscode and "Open" when set config.place_holder to "Open"' do
          @config.place_holder = 'Open'
          expect(Middleware.loadable?(@config)).to be true
          lines = Middleware.html_code.split("\n").map(&:strip)

          prefix = lines.find { |ln| ln =~ /^var\s*prefix/ }
          prefix = prefix.match(/prefix\s*=\s*'(.+?)';$/)[1]
          place_holder = lines.find { |ln| ln =~ /<a href=.+?open-code-rails-link/ }
          place_holder = place_holder.match(/open-code-rails-link">(.*?)<\/a>';$/)[1]

          expect(prefix.starts_with?("vscode://")).to be true
          expect(lines.find { |ln| ln =~ /\.open-code-rails-link::after/ }).to be_falsy
          expect(place_holder).to eq 'Open'
          expect(prefix.ends_with?(@config.root_dir)).to be true
        end

        it 'uses vscodium and "Open in VSCodium" when editor=vscodium, place_holder="Open in VSCodium"' do
          @config.editor = 'vscodium'
          @config.place_holder = 'Open in VSCodium'
          expect(Middleware.loadable?(@config)).to be true
          lines = Middleware.html_code.split("\n").map(&:strip)

          prefix = lines.find { |ln| ln =~ /^var\s*prefix/ }
          prefix = prefix.match(/prefix\s*=\s*'(.+?)';$/)[1]
          place_holder = lines.find { |ln| ln =~ /<a href=.+?open-code-rails-link/ }
          place_holder = place_holder.match(/open-code-rails-link">(.*?)<\/a>';$/)[1]

          expect(prefix.starts_with?("vscodium://")).to be true
          expect(lines.find { |ln| ln =~ /\.open-code-rails-link::after/ }).to be_falsy
          expect(place_holder).to eq 'Open in VSCodium'
          expect(prefix.ends_with?(@config.root_dir)).to be true
        end
      end
    end
  end
end
