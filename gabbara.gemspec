# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "gabbara/version"

Gem::Specification.new do |s|
  s.name        = "gabbara"
  s.version     = Gabbara::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Michael Reinsch", "Ron Evans"]
  s.email       = ["michael@mobalean.com", "ron dot evans at gmail dot com"]
  s.homepage    = ""
  s.summary     = %q{Easy server-side tracking for Google Analytics}
  s.description = %q{Easy server-side tracking for Google Analytics}

  s.rubyforge_project = "gabbara"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency("activesupport")
end
