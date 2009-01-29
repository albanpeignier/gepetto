namespace :puppet do
  desc "Check syntax of puppet manifests"
  task :check_syntax do
    sh "puppet --color=false --confdir=/tmp --vardir=/tmp --parseonly --ignoreimport #{FileList['manifests/**/*.pp'].join(' ')}"
  end
end
