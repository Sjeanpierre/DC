module GithubHelper
  require 'hashie'

  class GithubResult < Struct.new(:repo, :sha, :tag)
  end

  def get_repos
    git_connection = establish_git_connection
    accessible_repos = []
    member_organizations = get_organizations(git_connection)
    if member_organizations.count > 0
      org_names = []
      member_organizations.each { |org| org_names << org.login }
      org_names.each do |org|
        user_org_teams = get_org_teams(git_connection, org)
        user_org_teams.each do |team|
          team_repos = git_connection.orgs.teams.list_repos team.id
          team_repos.each { |repo| accessible_repos.push(repo) }
        end
      end
    end
    user_repos = git_connection.repos.list :type => 'all'
    user_repos.each { |repo| accessible_repos.push(repo) }
    accessible_repos.uniq!
    accessible_repos
  end

  def process_github_repos(repo_info, repos)
    tag_details = []
    if repo_info.keys.count > 1 #if we have more than one branch, if we only have one then we need to tag master for the one we don't have
      if  repo_info.values.uniq.count == 1 #if the names of the branches are the same across repos
        branch_name = repo_info.values.first
        tag_details.push(process_tags(repos, branch_name))
      else
        tag_name = repo_info.values.first
        repos.each do |repo|
          branch_name = repo_info[repo.repo_name]
          tag_details.push(process_tags([repo], branch_name, tag_name))
        end
      end
    else
      tag_name = repo_info.values.first
      repos.each do |repo|
        branch_name = repo_info[repo.repo_name] || 'master'
        tag_details.push(process_tags([repo], branch_name, tag_name))
      end
    end
    tag_details.flatten
  end

  private

  def get_organizations(git_connection)
    git_connection.orgs.list
  end

  def get_org_teams(git_connection, org)
    org_teams = git_connection.orgs.teams.list(org)
    org_teams.keep_if { |team| team.permission == 'push' }
    org_teams
  end


  def process_tags(repos, branch, tag_name=nil)
    tag_results = []
    tag_name = tag_name || branch
    tag = next_available_tag(repos, tag_name)
    repos.each do |repo|
      git_connection = establish_git_connection
      branch_info = git_connection.repos.branch(repo.repo_owner, repo.repo_name, branch)
      tag_results.push(tag_github_repo(git_connection, repo, tag, branch_info.commit.sha))
    end
    tag_results
  end

  def tag_github_repo(git_connection, repo, tag, commit_sha)
    repo_name = repo.repo_name
    repo_owner = repo.repo_owner
    tag = tag
    sha = commit_sha
    message = 'tagged by deployment API'
    user_name = 'deployment API'
    user_email = 'sageonedevops@sage.com'
    pushed_tag_information = git_connection.git_data.tags.create repo_owner, repo_name,
                                                                 'tag' => tag,
                                                                 'message' => message,
                                                                 'type' => 'commit',
                                                                 'object' => sha,
                                                                 'tagger' => {
                                                                     'name' => user_name,
                                                                     'email' => user_email,
                                                                     'date' => Time.now
                                                                 }
    tag_sha = pushed_tag_information['sha']
    git_connection.git_data.references.create repo_owner, repo_name,
                                              'ref' => "refs/tags/#{tag}",
                                              'sha' => tag_sha
    GithubResult.new(repo.repo_name,sha,tag)
  end

  def next_available_tag(repos, branch)
    top_tags = [0]
    tag_regex = /\b#{branch}\b[.]\d/
    repos.each do |repo|
      git_connection = establish_git_connection
      tag_list = git_connection.repos.tags(repo.repo_owner, repo.repo_name)
      tag_list.map! { |tag| tag.name }
      tag_list.select! { |tag| tag_regex.match(tag) }
      next if tag_list.empty?
      tag_list.map! { |tag| tag.split('.').last.to_i }
      top_tags.push(tag_list.max)
    end
    "#{branch}.#{top_tags.max + 1}"
  end

  def establish_git_connection
    Github.new :oauth_token => GITHUB_CONFIG['github_token']
  end


end