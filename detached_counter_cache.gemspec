Gem::Specification.new do |s|
  s.name        = 'detached_counter_cache'
  s.version     = '1.0.0'
  s.date        = '2016-07-20'
  s.summary     = 'counter cache that lives in its own table'
  s.description = 'counter cache that lives in its own table'
  s.authors     = ['Andrew Grim']
  s.email       = 'stopdropandrew@gmail.com'
  s.files       = ['lib/detached_counter_cache.rb']
  s.require_paths = ['lib']
  s.homepage    =
    'https://github.com/kongregate/detached_counter_cache'
  s.license     = 'MIT'

  s.add_runtime_dependency 'activerecord', '~> 4.2'

  s.add_development_dependency 'mysql2'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'byebug'
end
