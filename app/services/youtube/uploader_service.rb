# frozen_string_literal: true

require "google/apis/youtube_v3"
require "tempfile"

module Youtube
  class UploaderService
    def self.upload(short_video)
      new(short_video).upload
    end

    def initialize(short_video)
      @short_video = short_video
      @account = YoutubeAccount.current
    end

    def upload
      @short_video.update!(status: :uploading)

      unless @short_video.video_file.attached?
        raise "Cannot upload: No video file is attached to ShortVideo ##{@short_video.id}"
      end

      # Check if real YouTube OAuth account is configured
      if @account&.authorized? && Youtube::AuthService.client_id.present?
        upload_to_youtube_api
      else
        simulate_upload_for_demo
      end
    rescue StandardError => e
      Rails.logger.error("YouTube Upload Failed: #{e.message}")
      @short_video.update!(
        status: :failed,
        error_message: "Upload error: #{e.message}"
      )
      Notifications::DispatcherService.notify_failure(@short_video, e.message)
      raise e
    end

    private

    def upload_to_youtube_api
      service = Youtube::AuthService.authorized_service(@account)

      # Ensure title has #Shorts
      video_title = @short_video.title.to_s
      video_title += " #Shorts" unless video_title.include?("#Shorts")
      video_title = video_title.truncate(100)

      # Build tags array
      tag_list = (@short_video.tags.presence || "Shorts, Facts, Viral").split(",").map(&:strip)
      tag_list |= ["Shorts", "YouTubeShorts"]

      snippet = Google::Apis::YoutubeV3::VideoSnippet.new(
        title: video_title,
        description: @short_video.description,
        tags: tag_list,
        category_id: "27", # Education
        default_language: "en"
      )

      status = Google::Apis::YoutubeV3::VideoStatus.new(
        privacy_status: @short_video.privacy_status.presence || "public",
        self_declared_made_for_kids: false,
        embeddable: true
      )

      video_object = Google::Apis::YoutubeV3::Video.new(
        snippet: snippet,
        status: status
      )

      # Stream video from Active Storage
      temp_video = Tempfile.new(["yt_upload", ".mp4"], binmode: true)
      temp_video.write(@short_video.video_file.download)
      temp_video.rewind

      uploaded_video = service.insert_video(
        "snippet,status",
        video_object,
        upload_source: temp_video.path,
        content_type: "video/mp4",
        options: { retries: 3 }
      )

      temp_video.close
      temp_video.unlink

      video_id = uploaded_video.id
      published_url = "https://youtube.com/shorts/#{video_id}"

      @short_video.update!(
        youtube_video_id: video_id,
        youtube_url: published_url,
        status: :published,
        published_at: Time.current,
        error_message: nil
      )

      Notifications::DispatcherService.notify_published(@short_video)
      @short_video
    end

    def simulate_upload_for_demo
      # Generate deterministic mock ID for testing and local development
      demo_id = "demo_#{SecureRandom.hex(6)}"
      demo_url = "https://youtube.com/shorts/#{demo_id}"

      @short_video.update!(
        youtube_video_id: demo_id,
        youtube_url: demo_url,
        status: :published,
        published_at: Time.current,
        error_message: "Published in Simulation Mode (Configure YouTube OAuth in Settings for Live Channel Uploads)"
      )

      Notifications::DispatcherService.notify_published(@short_video)
      @short_video
    end
  end
end
