# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{gepetto}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Alban Peignier"]
  s.date = %q{2009-01-19}
  s.description = %q{A helper suite for Puppet projects to create, manage and help daily development  More information about Puppet: http://reductivelabs.com/trac/puppet/}
  s.email = ["alban.peignier@free.fr"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/albanpeignier/gepetto/}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{gepetto}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{A helper suite for Puppet projects to create, manage and help daily development  More information about Puppet: http://reductivelabs.com/trac/puppet/}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<newgem>, [">= 1.2.3"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<newgem>, [">= 1.2.3"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<newgem>, [">= 1.2.3"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end
