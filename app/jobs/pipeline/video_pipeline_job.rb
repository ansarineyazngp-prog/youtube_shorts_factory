# frozen_string_literal: true

module Pipeline
  class VideoPipelineJob < ApplicationJob
    queue_as :default

    discard_on StandardError do |job, error|
      short_video = job.arguments.first
      short_video = ShortVideo.find_by(id: short_video) unless short_video.is_a?(ShortVideo)
      if short_video
        short_video.update(
          status: :failed,
          error_message: error.message
        )
        Notifications::DispatcherService.notify_failure(short_video, error.message)
      end
    end

    def perform(short_video_or_id)
      short_video = short_video_or_id.is_a?(ShortVideo) ? short_video_or_id : ShortVideo.find(short_video_or_id)

      Rails.logger.info("=== Starting Video Pipeline for Short ##{short_video.id} ('#{short_video.topic}') ===")

      # Stage 1: Script & Metadata Generation
      short_video.update!(status: :scripting, error_message: nil)
      Shorts::ScriptGeneratorService.generate_for(short_video)

      # Stage 2: Audio & Voiceover Narration
      short_video.update!(status: :voiceover)
      Shorts::AudioGeneratorService.generate_for(short_video)

      # Stage 3: Visual & Scene Graphics
      short_video.update!(status: :visual_generation)
      visual_paths = Shorts::VisualGeneratorService.generate_for(short_video)

      # Stage 4: Video Assembly & Rendering
      short_video.update!(status: :assembling)
      assembly_success = Shorts::VideoAssemblerService.assemble_for(short_video, visual_paths)

      unless assembly_success
        raise "Video assembly failed during rendering"
      end

      # Stage 5: Decision Gate (Auto-Publish vs Manual Review)
      if short_video.auto_publish?
        Rails.logger.info("Auto-publish enabled for Short ##{short_video.id}. Proceeding directly to YouTube upload...")
        short_video.update!(status: :approved)
        Youtube::UploaderService.upload(short_video)
      else
        Rails.logger.info("Short ##{short_video.id} awaiting manual review.")
        short_video.update!(status: :ready_for_review)
        Notifications::DispatcherService.notify_needs_review(short_video)
      end

      Rails.logger.info("=== Pipeline completed successfully for Short ##{short_video.id} ===")
      short_video
    end
  end
end
