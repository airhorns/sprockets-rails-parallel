require 'ffi-rzmq'
require 'tmpdir'
require 'timeout'

module Sprockets
  module Rails
    class StaticCompiler
      KILL_MESSAGE = "die die die!!!!"

      def compile_with_workers
        unless ::Rails.application.config.assets.parallel_precompile
          return compile_without_workers
        end
        puts "Compiling in parallel."
        worker_count = (::Rails.application.config.assets.precompile_workers || 4).to_i

        paths = env.each_logical_path.reject {|logical_path| !compile_path?(logical_path)}
        total_count = paths.length
        manifest = {}

        dir = Dir.mktmpdir
        push_address = "ipc://#{dir}/push"
        pull_address = "ipc://#{dir}/pull"

        begin
          workers = 1.upto(worker_count).map do
            fork do
              child_context = ZMQ::Context.new(1)
              child_receiver = child_context.socket(ZMQ::PULL)
              child_sender = child_context.socket(ZMQ::PUSH)
              child_receiver.connect(push_address)
              child_sender.connect(pull_address)
              # Send synchronization string
              child_sender.send_string(Process.pid.to_s)

              loop do
                # Allocate, 0mq requires it. (lol)
                begin
                  logical_path = ""
                  child_receiver.recv_string(logical_path)
                rescue Interrupt
                  exit
                end
                if logical_path == KILL_MESSAGE
                  exit
                elsif asset = env.find_asset(logical_path)
                  child_sender.send_string(Marshal.dump(Hash[logical_path, write_asset(asset)]))
                end
              end
            end
          end

          context = ZMQ::Context.new(1)
          sender = context.socket(ZMQ::PUSH)
          receiver = context.socket(ZMQ::PULL)
          sender.bind(push_address)
          receiver.bind(pull_address)

          Timeout::timeout 5 do
            # Sync workers by blocking on a recieve from each one
            worker_count.times do |i|
              pid = ''
              receiver.recv_string(pid)
            end
          end

          paths.each do |path|
            sender.send_string(path)
          end

          total_count.times do |x|
            receiver.recv_string(string = "")
            result = Marshal.load(string)
            manifest.update result
          end

        ensure
          if workers
            workers.each {|pid| sender.send_string(KILL_MESSAGE) }
          end
        end

        write_manifest(manifest) if @manifest
      end

      alias_method_chain :compile, :workers
    end
  end
end
