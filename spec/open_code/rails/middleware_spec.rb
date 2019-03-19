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

      require_relative 'fake_middleware'
      describe 'Errors recovery' do
        before :each do
          FakeMiddleware.throw_error = false
        end

        it 'does not recover from errors from parent' do
          FakeMiddleware.throw_error = true
          expect { FakeMiddleware.test('undestructable') }.to raise_error(FakeError)
        end

        it 'recovers from errors from it self' do
          res = nil
          expect { res = FakeMiddleware.test('undestructable') }.not_to raise_error
          expect(res).to eq 'undestructable'
        end
      end

      describe 'HTTP status code handling' do
        it 'does not handle 200, 300, 400, 501, 502, 503' do
          %w[200 300 400 501 502 503].each do |code|
            res = [code, {}, ['']]
            expect(FakeMiddleware.test(res)).to be res
          end
        end

        it 'can handle 500 with bad payload' do
          env = [500]
          res = nil
          expect { res = FakeMiddleware.test(env) }.not_to raise_error
          expect(res).to eq env
        end

        it 'does not handle 500 with Content-Type responses rather than html' do
          %w[
            application/javascript
            application/json
            application/xml
            image/png
          ].each do |mime_type|
            env = [500, { 'Content-Type' => mime_type }, %w[FAKE]]
            res = nil
            expect { res = FakeMiddleware.test(env) }.not_to raise_error
            expect(res).to eq env
          end
        end

        it 'does not handle 500 with empty html' do
          %w[
            text/html
            application/xhtml+xml
          ].each do |mime_type|
            env = [500, { 'Content-Type' => mime_type }, %w[FAKE]]
            res = nil
            expect { res = FakeMiddleware.test(env) }.not_to raise_error
            expect(res[2]).to eq env[2]
          end
        end

        it 'handles 500 with HTML or XHTML' do
          %w[
            text/html
            application/xhtml+xml
          ].each do |mime_type|
            env = [500, { 'Content-Type' => mime_type }, %w[<html><body></body></html>]]
            res = nil
            expect { res = FakeMiddleware.test(env) }.not_to raise_error
            expect(res[2].size).to be 1
            expect(res[2][0].size).to be > env[2][0].size + 1000
          end
        end
      end
    end
  end
end
