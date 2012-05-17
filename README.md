# sprockets-rails-parallel

sprockets-rails-parallel is a dirty monkeypatchy hack to make `sprockets-rails` use many processes when precompiling assets. It uses zmq, so you'll need that.

## Installation

Add the gem to your gemfile and then in your `config/application.rb` or one of your environment files, add the following lines:

```ruby
config.assets.parallel_precompile = true
config.assets.precompile_workers = Integer `sysctl -n hw.ncpu 2>/dev/null` rescue 1 # or something like this
```

