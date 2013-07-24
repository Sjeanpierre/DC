class CreateDeploymentDetails < ActiveRecord::Migration
  def change
    create_table :deployment_details do |t|
      t.string :resource
      t.string :type
      t.string :value
      t.references :deployment

      t.timestamps
    end
    add_index :deployment_details, :deployment_id
  end
end
