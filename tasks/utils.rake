def sudo(command)
  sh "sudo #{command}"
end

def ssh(host, command, options = {})
  target = [ options.delete(:user), host ].compact.join('@')

  arguments = []

  arguments << "-p #{options.delete(:port)}" if options[:port]
  arguments = arguments + options.collect do |key, value|
    formatted_key = key.to_s.gsub('_','')
    "-o '#{formatted_key} #{value}'"
  end

  sh "ssh -t #{arguments.join(' ')} #{target} '#{command}'"
end
