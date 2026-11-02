# frozen_string_literal: true

class DailyShortsSchedulerJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info("=== Daily Autonomous YouTube Shorts Scheduler Triggered ===")

    # 1. Check if there are user-queued topics waiting in draft
    pending_short = ShortVideo.draft.order(created_at: :asc).first

    short_to_process = if pending_short.present?
                         Rails.logger.info("Found queued topic: '#{pending_short.topic}' (ID: #{pending_short.id})")
                         pending_short
                       else
                         # 2. Autonomous Mode: Auto-fetch trending topic
                         Rails.logger.info("No queued topics found. Generating trending topic autonomously...")
                         topic_data = Shorts::TrendingTopicService.fetch_trending_topic
                         account = YoutubeAccount.current

                         ShortVideo.create!(
                           topic: topic_data[:topic],
                           category: topic_data[:category],
                           auto_publish: account.auto_approve_default,
                           privacy_status: "public",
                           metadata: { source: topic_data[:source], auto_created: true }.to_json
                         )
                       end

    # 3. Trigger the asynchronous video production pipeline
    Rails.logger.info("Enqueuing VideoPipelineJob for Short ##{short_to_process.id} ('#{short_to_process.topic}')")
    Pipeline::VideoPipelineJob.perform_later(short_to_process.id)

    short_to_process
  end
end
