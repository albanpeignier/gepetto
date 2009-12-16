require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'

require File.dirname(__FILE__) + '/lib/gepetto'

Hoe.plugin :newgem

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'gepetto' do 
  self.version = Gepetto::VERSION
  self.developer('Alban Peignier', 'alban.peignier@free.fr')
  self.changes              = self.paragraphs_of("History.txt", 0..1).join("\n\n")
  self.rubyforge_name       = self.name # TODO this is default value
  self.extra_deps << ["rubigen"]

  self.clean_globs |= %w[**/.DS_Store tmp *.log]
  path = (self.rubyforge_name == self.name) ? self.rubyforge_name : "\#{self.rubyforge_name}/\#{self.name}"
  self.remote_rdoc_dir = File.join(path.gsub(/^#{self.rubyforge_name}\/?/,''), 'rdoc')
  self.rsync_args = '-av --delete --ignore-errors'
end

require 'newgem/tasks' # load /tasks/*.rake
Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# task :default => [:spec, :features]
