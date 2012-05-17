require 'ffi-rzmq'

module Sprockets
  module Rails
    class StaticCompiler
      WORKERS = 1

      def compile
        paths = env.each_logical_path.reject {|logical_path| !compile_path?(logical_path)}
        total_count = paths.length
        manifest = {}

        context = ZMQ::Context.new(1)
        sender = context.socket(ZMQ::PUSH)
        receiver = context.socket(ZMQ::PULL)

        sender.bind("tcp://127.0.0.1:55556")
        receiver.bind("tcp://127.0.0.1:55557")

        begin
          workers = 1.upto(WORKERS).map do
            fork do
              child_context = ZMQ::Context.new(1)
              receiver = child_context.socket(ZMQ::PULL)
              sender = child_context.socket(ZMQ::PUSH)
              receiver.connect("tcp://127.0.0.1:55556")
              sender.connect("tcp://127.0.0.1:55557")

              # Send synchronization string
              sender.send_string(Process.pid.to_s)

              loop do
                # Allocate, 0mq requires it. (lol)
                receiver.recv_string(logical_path = "")
                if asset = env.find_asset(logical_path)
                  ::Rails.logger.warn "Worker compiled asset #{logical_path} (pid: #{Process.pid})"
                  string = Marshal.dump(Hash[logical_path, write_asset(asset)])
                  sender.send_string(string.to_s)
                end
              end
            end
          end

          # Sync workers by blocking on a recieve from each one
          WORKERS.times do
            pid = ''
            receiver.recv_string(pid)
            puts "#{pid} connected!"
          end

          paths[0..1].each do |logical_path|
            puts "Send path #{logical_path}"
            sender.send_string(logical_path)
          end

          puts "Done sending"
          puts receiver
          receiver.recv_string(string = "")

          total_count.times do |x|
            puts "Recieving #{x}"
            receiver.recv_string(string = "")
            result = Marshal.load(string)
            manifest.update result
          end
          puts "Done receiving"

        ensure
          puts "Killing workers"
          if workers
            workers.each {|pid| Process.kill(:SIGINT, pid) }
          end
        end

        manifest
      end
    end
  end
end

def error_check(rc)
  if ZMQ::Util.resultcode_ok?(rc)
    false
  else
    STDERR.puts "Operation failed, errno [#{ZMQ::Util.errno}] description [#{ZMQ::Util.error_string}]"
    caller(1).each { |callstack| STDERR.puts(callstack) }
    true
  end
end
