require 'ffi-rzmq'
require 'thread'
require 'timeout'


module Sprockets
  module Rails
    class StaticCompiler
      KILL_MESSAGE = "die die die!!!!"

      def compile_with_workers
        unless ::Rails.application.config.assets.parallel_precompile
          return compile_without_workers
        end
        puts "Compiling in parallel w/ threads."
        #worker_count = (::Rails.application.config.assets.precompile_workers || 4).to_i
        thread_count = (::Rails.application.config.assets.precompile_workers || 12).to_i

        paths = env.each_logical_path.reject {|logical_path| !compile_path?(logical_path)}
        total_count = paths.length
        manifest = {}

        #j#jdir = Dir.mktmpdir
        #jpush_address = "ipc://#{dir}/push"
        #jpull_address = "ipc://#{dir}/pull"
        
        work_queue = Queue.new
        result_queue = Queue.new

          paths.each do |path|
            #sender.send_string(path.encode("UTF-8"))
            work_queue << path
          end

        begin
          threads = 1.upto(thread_count).map do
            #fork do
            Thread.new do
            puts 'spawned thread'
              #child_context = ZMQ::Context.new(1)
              #child_receiver = child_context.socket(ZMQ::PULL)
              #child_sender = child_context.socket(ZMQ::PUSH)
              #child_receiver.connect(push_address)
              #child_sender.connect(pull_address)
              ## Send synchronization string
              #child_sender.send_string(Process.pid.to_s)

              loop do
                # Allocate, 0mq requires it. (lol)
                begin
                  #logical_path = ""
                  logical_path = work_queue.pop(true)
                  #child_receiver.recv_string(logical_path)
                  logical_path.force_encoding("UTF-8")
                rescue ThreadError # queue is empty
                  break
                end

                #j#jif logical_path == KILL_MESSAGE
                  #jexit
                if asset = env.find_asset(logical_path)
                  puts 'got some data'
                  #child_sender.send_string(Marshal.dump(Hash[logical_path, write_asset(asset)]))
                  data = [logical_path, write_asset(asset)]
                  result_queue << data
                end
              end
            end
          end

          #context = ZMQ::Context.new(1)
          #sender = context.socket(ZMQ::PUSH)
          #receiver = context.socket(ZMQ::PULL)
          #sender.bind(push_address)
          #receiver.bind(pull_address)

          #Timeout::timeout 5 do
            ## Sync workers by blocking on a recieve from each one
            #worker_count.times do |i|
              #pid = ""
              #receiver.recv_string(pid)
            #end
          #end

          total_count.times do |x|
            #receiver.recv_string(string = "")
            #result = Marshal.load(string)
            puts 'received result'
            result = result_queue.pop
            manifest.update Hash[result]
          end
        ensure
          threads.each(&:join)
          #if workers
            #workers.each {|pid| sender.send_string(KILL_MESSAGE) }
            #workers.each {|pid| Process.waitpid(pid) }
          #end
        end
        write_manifest(manifest) if @manifest
      end

      alias_method_chain :compile, :workers
    end
  end
end
