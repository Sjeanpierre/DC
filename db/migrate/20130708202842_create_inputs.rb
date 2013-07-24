class CreateInputs < ActiveRecord::Migration
  def change
    create_table :inputs do |t|
      t.string :human_name
      t.string :rs_name
      t.string :type
      t.belongs_to :deployment_profile
      t.timestamps
    end
  end
end
