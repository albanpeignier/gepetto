# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "gepetto/version"

Gem::Specification.new do |s|
  s.name        = "gepetto"
  s.version     = Gepetto::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Alban Peignier"]
  s.email       = ["alban@tryphon.eu"]
  s.homepage    = "http://github.com/albanpeignier/gepetto/"
  s.summary     = %q{A helper suite for Puppet projects to create, manage and help daily development}
  s.description = %q{A helper suite for Puppet projects to create, manage and help daily development

More information about Puppet: http://reductivelabs.com/trac/puppet/}

  s.rubyforge_project = "gepetto"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "rubigen"
  s.add_dependency "rake"
end
