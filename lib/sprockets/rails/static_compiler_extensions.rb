require 'thread'

module Sprockets
  module Rails
    class StaticCompiler
      def compile_with_threads
        unless ::Rails.application.config.assets.parallel_precompile
          return compile_without_threads
        end

        thread_count = (::Rails.application.config.assets.precompile_threads || 12).to_i
        puts "Compiling in parallel w/ #{thread_count} threads."

        paths = env.each_logical_path.reject {|logical_path| !compile_path?(logical_path)}
        total_count = paths.length
        manifest = {}

        work_queue = Queue.new
        result_queue = Queue.new

        paths.each do |path|
          work_queue << path
        end

        threads = 1.upto(thread_count).map do
          Thread.new do
            loop do
              begin
                logical_path = work_queue.pop(:nonblock)
                logical_path.force_encoding("UTF-8")
              rescue ThreadError # queue is empty
                break
              end

              if asset = env.find_asset(logical_path)
                data = [logical_path, write_asset(asset)]
                result_queue << data
              end
            end
          end
        end

        total_count.times do |x|
          result = result_queue.pop
          manifest.update Hash[result]
        end

        write_manifest(manifest) if @manifest
      ensure
        threads.each(&:join)
      end

      alias_method_chain :compile, :threads
    end
  end
end
