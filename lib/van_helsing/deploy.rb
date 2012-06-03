settings.releases_path ||= lambda { "#{settings.deploy_to!}/releases" }
settings.shared_path   ||= lambda { "#{settings.deploy_to!}/shared" }
settings.current_path  ||= lambda { "#{settings.deploy_to!}/current" }
settings.lock_file     ||= lambda { "#{settings.deploy_to!}/deploy.lock" }

# WARNING: Don't use this, I'm thinking of deprecating it.
# Why? (1) The release path should be determined at the server, not locally.
# (2) The release should be built on a temp directory, then renamed to the actual release_path.
#
# The only thing that relies on this now is the deploy script.
settings.release_path  ||= lambda { "#{releases_path}/#{settings.current_version!}" }

namespace :deploy do
  desc "Forces a deploy unlock."
  task :force_unlock do
    queue %{echo "-----> Unlocking"}
    queue echo_cmd %{rm -f "#{lock_file}"}
  end

  desc "Links paths set in :shared_paths."
  task :link_shared_paths do
    dirs = settings.shared_paths!.map { |file| File.dirname("#{release_path}/#{file}") }.uniq

    cmds = dirs.map do |dir|
      %{mkdir -p "#{dir}"}
    end

    cmds += shared_paths.map do |file|
      %{ln -s "#{shared_path}/#{file}" "#{release_path}/#{file}"}
    end

    queue %{
      echo "-----> Symlinking shared paths"
      #{cmds.join(" &&\n")}
    }
  end
end

desc "Sets up a site."
task :setup do
  settings.deploy_to!

  queue %{echo "-----> Setting up"}
  queue echo_cmd %{mkdir -p "#{deploy_to}"}
  queue echo_cmd %{chmod g+r,a+rwx "#{deploy_to}"}
  queue echo_cmd %{mkdir -p "#{releases_path}"}
  queue echo_cmd %{mkdir -p "#{shared_path}"}
end