class Repo < ActiveRecord::Base
  attr_accessible :repo_name, :repo_owner
  has_many :deployment_profiles, :through => :deployment_profile_repos

  def self.grouped_by_owner
  #all.map {|repo| [repo.repo_owner, repo.repo_name]}
  repos_by_owner = all.group_by(&:repo_owner)
  gh_repos = {}
  repos_by_owner.each do |owner, repos|
    repos.each do |repo|
      if gh_repos.has_key?(owner)
        gh_repos[owner].push([repo.repo_name, repo.id])
      else
        gh_repos[owner] = []
        gh_repos[owner].push([repo.repo_name, repo.id])
      end
    end
  end
  gh_repos
  end

end