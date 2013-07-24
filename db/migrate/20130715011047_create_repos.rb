class CreateRepos < ActiveRecord::Migration
  def change
    create_table :repos do |t|
      t.string :repo_name
      t.string :repo_owner

      t.timestamps
    end
  end
end
