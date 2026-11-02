# frozen_string_literal: true

# Whenever Cron Configuration (config/schedule.rb)
# Use this file if deploying to a standard Linux server with Crontab.
# Run: bundle exec whenever --update-crontab

set :output, "log/cron.log"
set :environment, ENV.fetch("RAILS_ENV", "production")

# Trigger autonomous Shorts pipeline every day at 9:00 AM
every 1.day, at: "9:00 am" do
  runner "DailyShortsSchedulerJob.perform_later"
end

# Optional: Pre-fetch trending topics into drafts every Sunday at midnight
every :sunday, at: "12:00 am" do
  runner "Shorts::TrendingTopicService.fetch_trending_topic"
end
