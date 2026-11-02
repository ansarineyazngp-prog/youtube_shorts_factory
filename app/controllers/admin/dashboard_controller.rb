# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    def index
      @account = YoutubeAccount.current
      @total_videos = ShortVideo.count
      @published_count = ShortVideo.published.count
      @review_count = ShortVideo.needs_review.count
      @processing_count = ShortVideo.where(status: [:scripting, :voiceover, :visual_generation, :assembling, :uploading]).count
      @draft_count = ShortVideo.draft.count

      @recent_videos = ShortVideo.recent.limit(10)
      @needs_review_videos = ShortVideo.needs_review.recent.limit(5)
    end

    def trigger_daily_job
      DailyShortsSchedulerJob.perform_later
      redirect_to admin_dashboard_path, notice: "🚀 Daily autonomous pipeline job has been triggered!"
    end
  end
end
