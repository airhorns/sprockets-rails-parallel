require 'sprockets'
require 'sprockets-rails'

module Sprockets
  module Rails
    module Parallel

      class Railtie < ::Rails::Railtie
        config.after_initialize do |app|
          if app.config.assets.parallel_precompile
            require 'sprockets/rails/static_compiler_extensions.rb'
          end
        end
      end

    end
  end
end
