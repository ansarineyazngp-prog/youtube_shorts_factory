# frozen_string_literal: true

class YoutubeAccount < ApplicationRecord
  validates :channel_title, presence: true, on: :update

  def self.current
    where(is_active: true).order(created_at: :desc).first || create!(
      channel_title: "My YouTube Channel",
      auto_approve_default: false,
      notification_type: "discord"
    )
  end

  def authorized?
    refresh_token.present? || (access_token.present? && !token_expired?)
  end

  def token_expired?
    return true if token_expires_at.blank?
    token_expires_at <= Time.current + 2.minutes
  end
end
