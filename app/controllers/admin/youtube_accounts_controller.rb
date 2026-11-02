# frozen_string_literal: true

module Admin
  class YoutubeAccountsController < BaseController
    before_action :set_account

    def show
      redirect_to edit_admin_youtube_account_path
    end

    def edit
    end

    def update
      if @account.update(account_params)
        redirect_to edit_admin_youtube_account_path, notice: "Channel and automation settings updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def connect
      redirect_uri = admin_youtube_oauth_callback_url
      auth_url = Youtube::AuthService.authorization_url(redirect_uri)
      redirect_to auth_url, allow_other_host: true
    rescue StandardError => e
      redirect_to edit_admin_youtube_account_path, alert: "Could not initiate YouTube OAuth: #{e.message}. Make sure YOUTUBE_CLIENT_ID is set in .env."
    end

    def oauth_callback
      if params[:code].present?
        redirect_uri = admin_youtube_oauth_callback_url
        Youtube::AuthService.exchange_code(params[:code], redirect_uri)
        redirect_to edit_admin_youtube_account_path, notice: "🎉 YouTube Channel successfully authenticated! Automated uploads are active."
      else
        redirect_to edit_admin_youtube_account_path, alert: "OAuth failed: #{params[:error] || 'No authorization code returned'}"
      end
    rescue StandardError => e
      redirect_to edit_admin_youtube_account_path, alert: "Token exchange error: #{e.message}"
    end

    def disconnect
      @account.update!(access_token: nil, refresh_token: nil, is_active: false)
      redirect_to edit_admin_youtube_account_path, notice: "YouTube account disconnected."
    end

    private

    def set_account
      @account = YoutubeAccount.current
    end

    def account_params
      params.require(:youtube_account).permit(
        :channel_title,
        :auto_approve_default,
        :notification_type,
        :notification_webhook_url,
        :telegram_chat_id,
        :telegram_bot_token
      )
    end
  end
end
