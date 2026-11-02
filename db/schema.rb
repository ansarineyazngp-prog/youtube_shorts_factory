# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_02_192323) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "short_videos", force: :cascade do |t|
    t.string "topic", null: false
    t.string "category", default: "General"
    t.integer "status", default: 0, null: false
    t.boolean "auto_publish", default: false, null: false
    t.string "title"
    t.text "description"
    t.text "script_text"
    t.text "tags"
    t.string "youtube_video_id"
    t.string "youtube_url"
    t.string "privacy_status", default: "public", null: false
    t.datetime "scheduled_at"
    t.datetime "published_at"
    t.text "error_message"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_short_videos_on_created_at"
    t.index ["status"], name: "index_short_videos_on_status"
  end

  create_table "youtube_accounts", force: :cascade do |t|
    t.string "channel_title"
    t.string "channel_id"
    t.text "access_token"
    t.text "refresh_token"
    t.datetime "token_expires_at"
    t.boolean "is_active", default: true, null: false
    t.boolean "auto_approve_default", default: false, null: false
    t.string "notification_type", default: "discord"
    t.text "notification_webhook_url"
    t.string "telegram_chat_id"
    t.string "telegram_bot_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
