# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130627153742) do

  create_table "deployment_profiles", :force => true do |t|
    t.integer  "profile_id"
    t.integer  "rs_account"
    t.integer  "rs_deployment"
    t.integer  "rs_array"
    t.string   "rs_array_name"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "deployments", :force => true do |t|
    t.integer  "DeploymentProfile_id"
    t.string   "deployment_guid"
    t.string   "status"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  add_index "deployments", ["DeploymentProfile_id"], :name => "index_deployments_on_DeploymentProfile_id"

end
