namespace :puppet do
  desc "Check syntax of puppet manifests"
  task :check_syntax do
    FileList['manifests/**/*.pp'].each do |manifest|
      sh "puppet --color=false --confdir=/tmp --vardir=/tmp --parseonly --ignoreimport #{manifest}"
    end
  end
end
