Gem::Specification.new do |s|
  s.name      = 'sprockets-rails-parallel'
  s.version   = '0.0.1'
  s.date      = '2012-05-25'

  s.homepage    = "https://github.com/hornairs/sprockets-rails-parallel"
  s.summary     = "Precompile them assets with the power of modern computing!"
  s.description = ""

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency 'sprockets', "~>2.4.0"
  s.add_dependency 'ffi-rzmq', "~>0.8.0"
  s.add_dependency 'sprockets-rails'

  s.authors = ["Harry Brundage"]
  s.email   = "harry.brundage@jadedpixel.com"
end
