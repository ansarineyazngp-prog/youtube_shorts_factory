# 🎬 YouTube Shorts Factory • Autonomous AI Production Studio

A fully autonomous, scheduled, and self-publishing YouTube Shorts generator built with **Ruby on Rails 8.1**, **Solid Queue**, **FFmpeg**, and the **YouTube Data API v3**.

---

## ⚡ Key Architectural Features

1. **Autonomous Daily Cron Scheduler (Solid Queue Recurring):**
   - Built-in recurring schedule (`config/recurring.yml`) that triggers daily at 9:00 AM automatically without requiring Redis or cron daemons.
   - Also includes `config/schedule.rb` for `whenever` gem compatibility on standard Linux crontabs.
   - Automatically inspects the queue for pending draft topics, or autonomously generates a viral topic via AI.

2. **End-to-End Modular Production Pipeline:**
   - **AI Scriptwriter (`Shorts::ScriptGeneratorService`):** Generates viral hook, 30–45s narration script, SEO title, description, and monetization-compliant hashtags using Gemini / OpenAI with smart fallbacks.
   - **TTS Audio Engine (`Shorts::AudioGeneratorService`):** High-quality voiceover generation using OpenAI TTS, ElevenLabs, or synthesized fallback audio.
   - **Visual Storyboard Engine (`Shorts::VisualGeneratorService`):** Generates vertical 9:16 (1080x1920) graphic scenes with bold typography and cinematic color palettes.
   - **Video Assembler (`Shorts::VideoAssemblerService`):** Uses FFmpeg to assemble vertical 9:16 MP4s synchronized to narration duration with audio compression and fast-start flags.

3. **Approval Decision Gate:**
   - **Auto-Publish Mode ON:** Bypasses review and uploads straight to YouTube Shorts upon rendering.
   - **Auto-Publish Mode OFF (Manual Review):** Transitions the short to `ready_for_review`, attaches preview media, and sends a notification alert to Telegram/Discord with a 1-click approval button.

4. **YouTube Data API v3 Auto-Upload (`Youtube::UploaderService`):**
   - Built with Google OAuth2 (`google-apis-youtube_v3` & `googleauth`).
   - Automatically manages and refreshes access tokens using offline refresh tokens.
   - Inserts compliant video snippet, tags, and category (Education / Science), returning the direct `https://youtube.com/shorts/<id>` link.
   - Built-in simulation fallback for seamless local testing without blocking on YouTube API quota approval.

5. **Multi-Channel Notification Dispatcher (`Notifications::DispatcherService`):**
   - **Discord Webhook:** Sends rich embed cards with video title, topic, direct YouTube link, and action badges.
   - **Telegram Bot:** Sends direct Telegram messages with preview links and 1-click review URLs.

6. **Modern Dark-Mode Admin Dashboard:**
   - Glassmorphism UI with live pipeline progress stepper.
   - One-click viral topic launch radar across 4 high-converting niches (Psychology, Space & Science, AI & Tech, History Mysteries).
   - Embedded HTML5 vertical video player and audio player for previews.

---

## 🚀 Getting Started

### 1. Prerequisites
Ensure you have Ruby 3.4+ and FFmpeg installed:
```bash
sudo apt update && sudo apt install -y ffmpeg
```

### 2. Environment Variables
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Fill in your credentials:
```env
# AI Models
GEMINI_API_KEY=your_gemini_key
# or
OPENAI_API_KEY=your_openai_key

# Optional: ElevenLabs Hyperrealistic TTS
ELEVENLABS_API_KEY=your_elevenlabs_key

# YouTube Data API v3 OAuth2 (Google Cloud Console)
YOUTUBE_CLIENT_ID=your_client_id.apps.googleusercontent.com
YOUTUBE_CLIENT_SECRET=your_client_secret

# Notifications
NOTIFICATION_WEBHOOK_URL=https://discord.com/api/webhooks/...
TELEGRAM_BOT_TOKEN=your_bot_token
TELEGRAM_CHAT_ID=your_chat_id
```

### 3. Database Setup & Seeding
```bash
bin/rails db:migrate
bin/rails db:seed
```

### 4. Running the Application
Start the Rails web server:
```bash
bin/rails server
```
Open [http://localhost:3000/admin](http://localhost:3000/admin) in your browser.

To run background jobs and recurring cron scheduler in production or development:
```bash
bin/jobs
```

---

## 🧪 Testing the Autonomous Pipeline via CLI

Run a single video pipeline from the CLI:
```bash
bin/rails runner "DailyShortsSchedulerJob.perform_now"
```
Or generate and approve a short directly:
```bash
bin/rails runner "short = ShortVideo.draft.first; Pipeline::VideoPipelineJob.perform_now(short.id)"
```
