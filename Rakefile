require "rake"

desc "Build the gem"
task :build do
  sh "gem build elevenlabs.gemspec"
end

desc "Install the gem"
task :install => :build do
  sh "gem install ./elevenlabs-0.0.3.gem"
end

