# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Notifications
  class DispatcherService
    def self.notify_published(short_video)
      new(short_video).send_published_alert
    end

    def self.notify_needs_review(short_video)
      new(short_video).send_review_needed_alert
    end

    def self.notify_failure(short_video, error_msg)
      new(short_video).send_failure_alert(error_msg)
    end

    def initialize(short_video)
      @short_video = short_video
      @account = YoutubeAccount.current
    end

    def send_published_alert
      direct_url = @short_video.youtube_shorts_url || "https://youtube.com"

      message = <<~MSG
        🚀 **YouTube Short Successfully Published!**
        **Title:** #{@short_video.title}
        **Topic:** #{@short_video.topic}
        **Watch on YouTube:** #{direct_url}
      MSG

      dispatch_discord(
        title: "🎉 New YouTube Short Live!",
        description: "**#{@short_video.title}** has just been uploaded and published.",
        color: 0x10B981, # Emerald green
        url: direct_url,
        fields: [
          { name: "Topic", value: @short_video.topic, inline: true },
          { name: "Direct Link", value: "[Watch Short on YouTube](#{direct_url})", inline: false }
        ]
      )

      dispatch_telegram(
        text: "🎉 <b>YouTube Short Published!</b>\n\n<b>Title:</b> #{@short_video.title}\n<b>Topic:</b> #{@short_video.topic}\n\n👉 <a href='#{direct_url}'>Watch on YouTube Shorts</a>"
      )

      Rails.logger.info("Published notification sent for Short ##{@short_video.id}")
    end

    def send_review_needed_alert
      dashboard_url = Rails.application.routes.url_helpers.admin_short_video_url(@short_video, host: "localhost:3000") rescue "http://localhost:3000/admin/short_videos/#{@short_video.id}"

      dispatch_discord(
        title: "👀 Short Ready for Review!",
        description: "Video assembly completed. Waiting for your manual approval before uploading to YouTube.",
        color: 0xF59E0B, # Amber
        url: dashboard_url,
        fields: [
          { name: "Topic", value: @short_video.topic, inline: true },
          { name: "Action", value: "[Review & Approve in Admin](#{dashboard_url})", inline: false }
        ]
      )

      dispatch_telegram(
        text: "👀 <b>Short Ready for Review!</b>\n\n<b>Topic:</b> #{@short_video.topic}\n<b>Title:</b> #{@short_video.title}\n\n👉 <a href='#{dashboard_url}'>Click here to Approve & Publish</a>"
      )
    end

    def send_failure_alert(error_msg)
      dispatch_discord(
        title: "⚠️ Pipeline Failed!",
        description: "Error occurred while generating/uploading short for topic: **#{@short_video.topic}**\n\n`#{error_msg}`",
        color: 0xEF4444 # Red
      )

      dispatch_telegram(
        text: "⚠️ <b>Pipeline Error!</b>\n\n<b>Topic:</b> #{@short_video.topic}\n<b>Error:</b> #{error_msg}"
      )
    end

    private

    def webhook_url
      @account.notification_webhook_url.presence || ENV["NOTIFICATION_WEBHOOK_URL"]
    end

    def dispatch_discord(title:, description:, color:, url: nil, fields: [])
      return if webhook_url.blank? || !webhook_url.include?("discord.com")

      payload = {
        embeds: [{
          title: title,
          description: description,
          url: url,
          color: color,
          timestamp: Time.current.iso8601,
          fields: fields,
          footer: { text: "YouTube Shorts Factory • Autonomous Pipeline" }
        }]
      }

      send_http_post(webhook_url, payload)
    rescue StandardError => e
      Rails.logger.warn("Discord webhook delivery failed: #{e.message}")
    end

    def dispatch_telegram(text:)
      bot_token = @account.telegram_bot_token.presence || ENV["TELEGRAM_BOT_TOKEN"]
      chat_id = @account.telegram_chat_id.presence || ENV["TELEGRAM_CHAT_ID"]

      return if bot_token.blank? || chat_id.blank?

      url = URI("https://api.telegram.org/bot#{bot_token}/sendMessage")
      payload = {
        chat_id: chat_id,
        text: text,
        parse_mode: "HTML",
        disable_web_page_preview: false
      }

      send_http_post(url.to_s, payload)
    rescue StandardError => e
      Rails.logger.warn("Telegram alert delivery failed: #{e.message}")
    end

    def send_http_post(target_url, body_hash)
      uri = URI(target_url)
      req = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
      req.body = body_hash.to_json

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 10) do |http|
        http.request(req)
      end
    end
  end
end
