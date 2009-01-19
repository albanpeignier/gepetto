require 'rbconfig'

class GepettoGenerator < RubiGen::Base

  def initialize(runtime_args, runtime_options = {})
    super

    usage if args.empty?
    @destination_root = File.expand_path(args.shift)
  end

  def manifest
    script_options = { :chmod => 0755 }
    
    record do |m|
      # Root directory and all subdirectories.
      m.directory ''
      %w{script manifests files templates tasks}.each { |path| m.directory path }

      m.template_copy_each %w( Rakefile )

      m.template_copy_each %w( site.pp templates.pp nodes.pp ), 'manifests'

      m.template_copy_each %w( server puppetca ), 'script', script_options

      m.template_copy_each %w( log.rake tmp.rake ), 'tasks'

      m.dependency "install_rubigen_scripts", [destination_root, "puppet"]
    end
  end

end
