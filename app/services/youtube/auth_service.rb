# frozen_string_literal: true

require "google/apis/youtube_v3"
require "googleauth"
require "googleauth/stores/file_token_store"

module Youtube
  class AuthService
    OAUTH_SCOPE = [
      Google::Apis::YoutubeV3::AUTH_YOUTUBE_UPLOAD,
      Google::Apis::YoutubeV3::AUTH_YOUTUBE_READONLY
    ].freeze

    def self.client_id
      ENV["YOUTUBE_CLIENT_ID"].presence || Rails.application.credentials.dig(:youtube, :client_id)
    end

    def self.client_secret
      ENV["YOUTUBE_CLIENT_SECRET"].presence || Rails.application.credentials.dig(:youtube, :client_secret)
    end

    def self.oauth_client(redirect_uri = nil)
      Signet::OAuth2::Client.new(
        authorization_uri: "https://accounts.google.com/o/oauth2/auth",
        token_credential_uri: "https://oauth2.googleapis.com/token",
        client_id: client_id,
        client_secret: client_secret,
        scope: OAUTH_SCOPE.join(" "),
        redirect_uri: redirect_uri,
        access_type: "offline",
        approval_prompt: "force"
      )
    end

    def self.authorization_url(redirect_uri)
      client = oauth_client(redirect_uri)
      client.authorization_uri.to_s
    end

    def self.exchange_code(code, redirect_uri)
      client = oauth_client(redirect_uri)
      client.code = code
      client.fetch_access_token!

      # Fetch channel details to store name and channel ID
      service = Google::Apis::YoutubeV3::YouTubeService.new
      service.authorization = client
      channels_response = service.list_channels("snippet", mine: true)
      channel = channels_response.items&.first

      account = YoutubeAccount.current
      account.update!(
        channel_title: channel&.snippet&.title || "Connected YouTube Channel",
        channel_id: channel&.id,
        access_token: client.access_token,
        refresh_token: client.refresh_token || account.refresh_token,
        token_expires_at: client.expires_at,
        is_active: true
      )

      account
    end

    def self.refresh_token_if_needed(account = YoutubeAccount.current)
      return unless account&.refresh_token.present?

      if account.token_expired? || account.access_token.blank?
        client = oauth_client
        client.refresh_token = account.refresh_token
        client.fetch_access_token!

        account.update!(
          access_token: client.access_token,
          token_expires_at: client.expires_at
        )
      end

      account.access_token
    rescue StandardError => e
      Rails.logger.error("Failed to refresh YouTube token: #{e.message}")
      nil
    end

    def self.authorized_service(account = YoutubeAccount.current)
      refresh_token_if_needed(account)

      service = Google::Apis::YoutubeV3::YouTubeService.new
      client = oauth_client
      client.access_token = account.access_token
      client.refresh_token = account.refresh_token
      service.authorization = client
      service
    end
  end
end
