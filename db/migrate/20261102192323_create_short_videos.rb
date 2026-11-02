class CreateShortVideos < ActiveRecord::Migration[8.1]
  def change
    create_table :short_videos do |t|
      t.string :topic, null: false
      t.string :category, default: "General"
      t.integer :status, default: 0, null: false
      t.boolean :auto_publish, default: false, null: false
      t.string :title
      t.text :description
      t.text :script_text
      t.text :tags
      t.string :youtube_video_id
      t.string :youtube_url
      t.string :privacy_status, default: "public", null: false
      t.datetime :scheduled_at
      t.datetime :published_at
      t.text :error_message
      t.text :metadata

      t.timestamps
    end

    add_index :short_videos, :status
    add_index :short_videos, :created_at
  end
end
