# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{gepetto}
  s.version = "0.0.11"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Alban Peignier"]
  s.date = %q{2010-02-05}
  s.default_executable = %q{gepetto}
  s.description = %q{A helper suite for Puppet projects to create, manage and help daily development

More information about Puppet: http://reductivelabs.com/trac/puppet/}
  s.email = ["alban.peignier@free.fr"]
  s.executables = ["gepetto"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.rdoc", "Rakefile", "app_generators/gepetto/USAGE", "app_generators/gepetto/gepetto_generator.rb", "app_generators/gepetto/templates/Rakefile", "app_generators/gepetto/templates/config/fileserver.conf", "app_generators/gepetto/templates/config/puppet.conf", "app_generators/gepetto/templates/config/qemu-ifup", "app_generators/gepetto/templates/manifests/classes/empty.pp", "app_generators/gepetto/templates/manifests/defaults.pp", "app_generators/gepetto/templates/manifests/nodes.pp", "app_generators/gepetto/templates/manifests/sandbox-sample.pp", "app_generators/gepetto/templates/manifests/sandbox.pp", "app_generators/gepetto/templates/manifests/site.pp", "app_generators/gepetto/templates/manifests/templates.pp", "app_generators/gepetto/templates/script/module", "app_generators/gepetto/templates/script/puppetca", "app_generators/gepetto/templates/script/puppetmasterd", "app_generators/gepetto/templates/script/puppetrun", "bin/gepetto", "gepetto.gemspec", "lib/gepetto.rb", "lib/gepetto/tasks.rb", "puppet_generators/module/USAGE", "puppet_generators/module/module_generator.rb", "puppet_generators/module/templates/README", "puppet_generators/module/templates/manifests/init.pp", "script/destroy", "script/generate", "tasks/host.pp", "tasks/log.rake", "tasks/puppet.rake", "tasks/sandbox.pp", "tasks/sandbox.rake", "tasks/tmp.rake", "tasks/utils.rake"]
  s.homepage = %q{http://github.com/albanpeignier/gepetto/}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{gepetto}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{A helper suite for Puppet projects to create, manage and help daily development  More information about Puppet: http://reductivelabs.com/trac/puppet/}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rubigen>, [">= 0"])
      s.add_runtime_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rubyforge>, [">= 2.0.3"])
      s.add_development_dependency(%q<gemcutter>, [">= 0.3.0"])
      s.add_development_dependency(%q<hoe>, [">= 2.5.0"])
    else
      s.add_dependency(%q<rubigen>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rubyforge>, [">= 2.0.3"])
      s.add_dependency(%q<gemcutter>, [">= 0.3.0"])
      s.add_dependency(%q<hoe>, [">= 2.5.0"])
    end
  else
    s.add_dependency(%q<rubigen>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rubyforge>, [">= 2.0.3"])
    s.add_dependency(%q<gemcutter>, [">= 0.3.0"])
    s.add_dependency(%q<hoe>, [">= 2.5.0"])
  end
end
