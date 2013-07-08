class CreateDeployments < ActiveRecord::Migration
  def change
    create_table :deployments do |t|
      t.references :DeploymentProfile
      t.string :deployment_guid
      t.string :status

      t.timestamps
    end
    add_index :deployments, :DeploymentProfile_id
  end
end
