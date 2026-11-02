# frozen_string_literal: true

module Admin
  class ShortVideosController < BaseController
    before_action :set_short_video, only: [:show, :edit, :update, :destroy, :approve, :trigger_pipeline]

    def index
      @filter = params[:status]
      @short_videos = ShortVideo.recent
      @short_videos = @short_videos.where(status: @filter) if @filter.present?
      @short_videos = @short_videos.limit(50)
    end

    def show
      @metadata = @short_video.metadata.present? ? (JSON.parse(@short_video.metadata) rescue {}) : {}
    end

    def new
      @short_video = ShortVideo.new(
        auto_publish: YoutubeAccount.current.auto_approve_default,
        category: "Psychology"
      )
    end

    def create
      @short_video = ShortVideo.new(short_video_params)

      if @short_video.save
        if params[:run_now] == "1"
          Pipeline::VideoPipelineJob.perform_later(@short_video.id)
          redirect_to admin_short_video_path(@short_video), notice: "Short created and generation pipeline started!"
        else
          redirect_to admin_dashboard_path, notice: "Topic added to the daily automation queue."
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @short_video.update(short_video_params)
        redirect_to admin_short_video_path(@short_video), notice: "Short video details updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @short_video.destroy
      redirect_to admin_dashboard_path, notice: "Video deleted successfully."
    end

    def approve
      if @short_video.can_approve?
        @short_video.update!(status: :approved)
        YoutubeUploadJob.perform_later(@short_video.id) rescue Youtube::UploaderService.upload(@short_video)
        redirect_to admin_short_video_path(@short_video), notice: "Short approved! Uploading to YouTube now..."
      else
        redirect_to admin_short_video_path(@short_video), alert: "Video cannot be approved in its current status."
      end
    end

    def trigger_pipeline
      Pipeline::VideoPipelineJob.perform_later(@short_video.id)
      redirect_to admin_short_video_path(@short_video), notice: "Pipeline triggered for this video!"
    end

    def fetch_trending
      category = params[:category]
      topic_data = Shorts::TrendingTopicService.fetch_trending_topic(category)

      short = ShortVideo.create!(
        topic: topic_data[:topic],
        category: topic_data[:category],
        auto_publish: YoutubeAccount.current.auto_approve_default,
        metadata: { source: topic_data[:source] }.to_json
      )

      if params[:run_now] == "1"
        Pipeline::VideoPipelineJob.perform_later(short.id)
        redirect_to admin_short_video_path(short), notice: "Trending topic '#{short.topic}' generated and pipeline started!"
      else
        redirect_to admin_dashboard_path, notice: "Trending topic '#{short.topic}' added to queue!"
      end
    end

    private

    def set_short_video
      @short_video = ShortVideo.find(params[:id])
    end

    def short_video_params
      params.require(:short_video).permit(:topic, :category, :auto_publish, :privacy_status, :title, :description, :script_text, :tags)
    end
  end
end
