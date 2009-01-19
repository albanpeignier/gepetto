require 'rbconfig'

class ModuleGenerator < RubiGen::Base

  attr_reader :module_name

  def initialize(runtime_args, runtime_options = {})
    super
    usage if args.empty?
    @module_name = args.shift
    @destination_root = "modules/#{module_name}"
  end

  def manifest
    record do |m|
      # Root directory and all subdirectories.
      m.directory ''
      %w{manifests files templates}.each { |path| m.directory path }
      m.template_copy_each %w( README )
      m.template_copy_each %w( init.pp ), 'manifests'
    end
  end

end
