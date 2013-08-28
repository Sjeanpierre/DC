class CreateAuditEntries < ActiveRecord::Migration
  def change
    create_table :audit_entries do |t|
      t.references :deployment
      t.string :audit_type
      t.text :details

      t.timestamps
    end
    add_index :audit_entries, :deployment_id
  end
end
