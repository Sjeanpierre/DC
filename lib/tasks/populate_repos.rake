namespace :populate do
	desc 'Populates repo table with repos that are accessible from current github token'
	task :repos => :environment do
    include GithubHelper
    repos = get_repos
    repos.each do |repo|
      puts "processing repo name #{repo.full_name}"
      repo_name = repo.full_name.split('/')
      new_repo = Repo.new
      new_repo.repo_name = repo_name[1]
      new_repo.repo_owner = repo_name[0]
      new_repo.save!
    end
	end
end