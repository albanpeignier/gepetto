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

      %w{script config manifests manifests/classes files templates log tasks}.each { |path| m.directory path }

      m.template_copy_each %w( Rakefile )

      m.template_copy_each %w( defaults.pp site.pp templates.pp nodes.pp ), 'manifests'

      m.template_copy_each %w( defaults.pp site.pp templates.pp nodes.pp ), 'manifests'

      m.template_copy_each %w( sandbox.pp sandbox-sample.pp ), 'manifests'

      m.template_copy_each %w( empty.pp ), 'manifests/classes'

      m.template_copy_each %w( puppet.conf fileserver.conf ), 'config'
      m.template_copy_each %w( qemu-ifup ), 'config', script_options

      m.template_copy_each %w( puppetmasterd puppetca puppetrun module ), 'script', script_options

      m.dependency "install_rubigen_scripts", [destination_root, "puppet"]
    end
  end

end
