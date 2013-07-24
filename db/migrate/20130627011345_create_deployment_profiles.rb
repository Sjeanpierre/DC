class CreateDeploymentProfiles < ActiveRecord::Migration
  def change
    create_table :deployment_profiles do |t|
      t.string :profile_id
      t.integer :rs_account
      t.integer :rs_deployment
      t.integer :rs_array
      t.string  :rs_array_name
      t.string  :domain
      t.timestamps
    end
  end
end
