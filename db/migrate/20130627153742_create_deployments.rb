class CreateDeployments < ActiveRecord::Migration
  def change
    create_table :deployments do |t|
      t.belongs_to :deployment_profile
      t.string :deployment_guid
      t.string :status
      t.datetime :expires

      t.timestamps
    end
    add_index :deployments, :deployment_profile_id
  end
end
