class CreateDeploymentProfileRepos < ActiveRecord::Migration
  def change
    create_table :deployment_profile_repos, :id => false do |t|
      t.integer :deployment_profile_id
      t.integer :repo_id
      t.timestamps
    end
  end
end
