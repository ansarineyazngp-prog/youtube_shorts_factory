# frozen_string_literal: true

class ShortVideo < ApplicationRecord
  has_one_attached :video_file
  has_one_attached :audio_file
  has_one_attached :thumbnail

  enum :status, {
    draft: 0,
    scripting: 1,
    voiceover: 2,
    visual_generation: 3,
    assembling: 4,
    ready_for_review: 5,
    approved: 6,
    uploading: 7,
    published: 8,
    failed: 9
  }, default: :draft

  validates :topic, presence: true

  scope :pending_or_processing, -> { where(status: [:draft, :scripting, :voiceover, :visual_generation, :assembling, :approved, :uploading]) }
  scope :needs_review, -> { where(status: :ready_for_review) }
  scope :published_videos, -> { where(status: :published).order(published_at: :desc) }
  scope :recent, -> { order(created_at: :desc) }

  def youtube_shorts_url
    return youtube_url if youtube_url.present?
    return "https://youtube.com/shorts/#{youtube_video_id}" if youtube_video_id.present?
    nil
  end

  def can_approve?
    ready_for_review?
  end

  def can_retry?
    failed? || draft?
  end

  def processing?
    scripting? || voiceover? || visual_generation? || assembling? || uploading?
  end

  def status_color
    case status.to_sym
    when :published then "bg-emerald-500/20 text-emerald-400 border-emerald-500/30"
    when :ready_for_review then "bg-amber-500/20 text-amber-400 border-amber-500/30"
    when :failed then "bg-rose-500/20 text-rose-400 border-rose-500/30"
    when :draft then "bg-slate-500/20 text-slate-400 border-slate-500/30"
    else "bg-indigo-500/20 text-indigo-400 border-indigo-500/30"
    end
  end

  def status_step_index
    case status.to_sym
    when :draft then 0
    when :scripting then 1
    when :voiceover then 2
    when :visual_generation then 3
    when :assembling then 4
    when :ready_for_review, :approved then 5
    when :uploading then 6
    when :published then 7
    when :failed then -1
    else 0
    end
  end
end
