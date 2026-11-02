# frozen_string_literal: true

require "net/http"
require "json"
require "uri"
require "fileutils"

module Shorts
  class VisualGeneratorService
    def self.generate_for(short_video)
      new(short_video).generate
    end

    def initialize(short_video)
      @short_video = short_video
      @output_dir = Rails.root.join("tmp", "shorts_assets", "video_#{@short_video.id}")
      FileUtils.mkdir_p(@output_dir)
    end

    def generate
      metadata = @short_video.metadata.present? ? JSON.parse(@short_video.metadata) : {}
      scenes = metadata["scenes"] || []

      image_paths = []

      if scenes.empty?
        scenes = [
          { "caption" => @short_video.title, "visual_prompt" => @short_video.topic },
          { "caption" => "The Shocking Secret", "visual_prompt" => "#{@short_video.topic} mystery" },
          { "caption" => "What Science Says", "visual_prompt" => "#{@short_video.topic} facts" },
          { "caption" => "Subscribe for More!", "visual_prompt" => "#{@short_video.topic} conclusion" }
        ]
      end

      scenes.each_with_index do |scene, idx|
        img_path = @output_dir.join("scene_#{idx + 1}.png").to_s
        generate_slide_image(scene["caption"] || @short_video.topic, scene["visual_prompt"], img_path, idx)
        image_paths << img_path
      end

      image_paths
    end

    private

    def generate_slide_image(caption, prompt_text, target_path, index)
      # Colors for 9:16 vertical shorts visual gradients
      color_schemes = [
        ["#0f172a", "#1e1b4b", "#6366f1"],
        ["#18181b", "#27272a", "#ef4444"],
        ["#064e3b", "#022c22", "#10b981"],
        ["#4c1d95", "#2e1065", "#a855f7"]
      ]
      scheme = color_schemes[index % color_schemes.length]

      # Generate high-res 1080x1920 SVG slide, then rasterize or generate with FFmpeg
      # To ensure maximum compatibility without ImageMagick or external node:
      # We create an SVG card and convert it with ffmpeg or rsvg-convert, or direct ffmpeg drawtext filter!
      svg_content = <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1920" viewBox="0 0 1080 1920">
          <defs>
            <linearGradient id="grad#{index}" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" style="stop-color:#{scheme[0]};stop-opacity:1" />
              <stop offset="50%" style="stop-color:#{scheme[1]};stop-opacity:1" />
              <stop offset="100%" style="stop-color:#{scheme[2]};stop-opacity:1" />
            </linearGradient>
            <radialGradient id="glow#{index}" cx="50%" cy="30%" r="50%">
              <stop offset="0%" style="stop-color:#ffffff;stop-opacity:0.15" />
              <stop offset="100%" style="stop-color:#000000;stop-opacity:0" />
            </radialGradient>
          </defs>
          <rect width="1080" height="1920" fill="url(#grad#{index})" />
          <circle cx="540" cy="500" r="450" fill="url(#glow#{index})" />

          <!-- Top Badge -->
          <rect x="360" y="220" width="360" height="70" rx="35" fill="rgba(255,255,255,0.12)" stroke="rgba(255,255,255,0.25)" stroke-width="2"/>
          <text x="540" y="265" font-family="Arial, sans-serif" font-size="28" font-weight="bold" fill="#38bdf8" text-anchor="middle">FACT OF THE DAY</text>

          <!-- Main Caption / Hook -->
          <foreignObject x="90" y="650" width="900" height="600">
            <div xmlns="http://www.w3.org/1999/xhtml" style="font-family: 'Arial Black', Impact, sans-serif; font-size: 58px; font-weight: 900; color: #ffffff; text-align: center; line-height: 1.35; text-shadow: 0 10px 30px rgba(0,0,0,0.8);">
              #{CGI.escapeHTML(caption.to_s.truncate(130))}
            </div>
          </foreignObject>

          <!-- Bottom Branding -->
          <rect x="190" y="1550" width="700" height="90" rx="45" fill="rgba(0,0,0,0.5)" stroke="rgba(255,255,255,0.2)" stroke-width="2"/>
          <text x="540" y="1608" font-family="Arial, sans-serif" font-size="32" font-weight="bold" fill="#facc15" text-anchor="middle">🔥 SUBSCRIBE FOR MORE SHORTS</text>
        </svg>
      SVG

      svg_path = target_path.gsub(/\.png$/, ".svg")
      File.write(svg_path, svg_content)

      # Convert svg to png using ffmpeg
      system("ffmpeg -y -i #{svg_path} -vf \"scale=1080:1920\" #{target_path} > /dev/null 2>&1")

      unless File.exist?(target_path) && File.size(target_path) > 0
        # If ffmpeg didn't rasterize svg, generate color canvas directly with ffmpeg lavfi
        system("ffmpeg -y -f lavfi -i color=c=#{scheme[0].gsub('#', '0x')}:s=1080x1920:d=1 -vframes 1 #{target_path} > /dev/null 2>&1")
      end
    end
  end
end
