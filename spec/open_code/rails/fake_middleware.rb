module OpenCode
  module Rails
    class FakeError < StandardError; end

    class FakeMiddleware
      class << self
        attr_accessor :throw_error

        def call(env)
          raise(FakeError, 'fake error') if throw_error
          env
        end

        def test(env)
          middleware = Middleware.new(self)
          middleware.call(env)
        end
      end
    end
  end
end
