# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "watir/version"

Gem::Specification.new do |s|
  s.name        = "watir"
  s.version     = Watir::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jari Bakken, Titus Fortner, Alex Rodionov"]
  s.email       = ["titus.fortner@gmail.com", "p0deje@gmail.com"]
  s.homepage    = "http://github.com/watir/watir"
  s.summary     = %q{Watir}
  s.description = %q{Watir}
  s.license     = 'MIT'

  s.rubyforge_project = "watir"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "selenium-webdriver", ">= 2.46.2"

  s.add_development_dependency "rspec", "~> 2.6"
  s.add_development_dependency "yard", "> 0.8.2.1"
  s.add_development_dependency "webidl", ">= 0.1.5"
  s.add_development_dependency "sinatra", "~> 1.0"
  s.add_development_dependency "rake", "~> 0.9.2"
  s.add_development_dependency "fuubar"
  s.add_development_dependency "nokogiri"
  s.add_development_dependency "activesupport", "~> 3.0" # for pluralization during code generation
  s.add_development_dependency "pry"
  s.add_development_dependency "coveralls"
  s.add_development_dependency "yard-doctest", "~> 0.1.5"
end
