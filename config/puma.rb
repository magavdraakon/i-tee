workers Integer(ENV['WEB_CONCURRENCY'] || 10)
threads_count = Integer(ENV['MAX_THREADS'] || 5)
threads threads_count, threads_count

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 80
environment ENV['RACK_ENV'] || 'production'
plugin :tmp_restart



pidfile '/tmp/puma.pid'


on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end
end

before_fork do
  ActiveRecord::Base.connection_pool.disconnect!
end