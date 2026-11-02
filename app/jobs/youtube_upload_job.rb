# frozen_string_literal: true

class YoutubeUploadJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 30.seconds, attempts: 3

  def perform(short_video_id)
    short_video = ShortVideo.find(short_video_id)
    Youtube::UploaderService.upload(short_video)
  end
end
