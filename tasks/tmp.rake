namespace :tmp do

  TMP_DIRECTORIES = %w( tmp/lib tmp/ssl tmp/run )          

  desc "Clear puppetmaster data, ssl, pids files from tmp/"
  task :clear => [ "tmp:lib:clear",  "tmp:ssl:clear", "tmp:run:clear" ]

  desc "Creates tmp directories for puppetmaster data and ssl files"
  task :create do
    FileUtils.mkdir_p(TMP_DIRECTORIES)
  end

  TMP_DIRECTORIES.each do |tmp_directory|
    name = File.basename(tmp_directory)
    
    namespace name do
      desc "Clears all files in #{tmp_directory}"
      task :clear do
        files = Dir["#{tmp_directory}/**/*"].reject { |f| File.directory?(f) }
        unless files.empty?
          puts "* remove #{files.size} files in #{tmp_directory}"
          FileUtils.rm files
        end
      end
    end
  end

end
