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

ActiveRecord::Schema.define(:version => 20130727233635) do

  create_table "audit_entries", :force => true do |t|
    t.integer  "deployment_id"
    t.string   "audit_type"
    t.text     "details"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "audit_entries", ["deployment_id"], :name => "index_audit_entries_on_deployment_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "deployment_details", :force => true do |t|
    t.string   "resource"
    t.string   "type"
    t.string   "value"
    t.integer  "deployment_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "deployment_details", ["deployment_id"], :name => "index_deployment_details_on_deployment_id"

  create_table "deployment_profile_repos", :id => false, :force => true do |t|
    t.integer  "deployment_profile_id"
    t.integer  "repo_id"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  create_table "deployment_profiles", :force => true do |t|
    t.string   "profile_id"
    t.integer  "rs_account"
    t.integer  "rs_deployment"
    t.integer  "rs_array"
    t.string   "rs_array_name"
    t.string   "domain"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "deployments", :force => true do |t|
    t.integer  "deployment_profile_id"
    t.string   "deployment_guid"
    t.string   "status"
    t.datetime "expires"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  add_index "deployments", ["deployment_profile_id"], :name => "index_deployments_on_deployment_profile_id"

  create_table "inputs", :force => true do |t|
    t.string   "human_name"
    t.string   "rs_name"
    t.string   "input_type"
    t.integer  "deployment_profile_id"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  create_table "repos", :force => true do |t|
    t.string   "repo_name"
    t.string   "repo_owner"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

end
