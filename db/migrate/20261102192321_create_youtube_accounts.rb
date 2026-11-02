class CreateYoutubeAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :youtube_accounts do |t|
      t.string :channel_title
      t.string :channel_id
      t.text :access_token
      t.text :refresh_token
      t.datetime :token_expires_at
      t.boolean :is_active, default: true, null: false
      t.boolean :auto_approve_default, default: false, null: false
      t.string :notification_type, default: "discord"
      t.text :notification_webhook_url
      t.string :telegram_chat_id
      t.string :telegram_bot_token

      t.timestamps
    end
  end
end
