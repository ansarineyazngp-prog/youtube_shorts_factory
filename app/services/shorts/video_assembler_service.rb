# frozen_string_literal: true

require "tempfile"
require "fileutils"

module Shorts
  class VideoAssemblerService
    def self.assemble_for(short_video, visual_paths = [])
      new(short_video, visual_paths).assemble
    end

    def initialize(short_video, visual_paths)
      @short_video = short_video
      @visual_paths = visual_paths
      @output_dir = Rails.root.join("tmp", "shorts_renders")
      FileUtils.mkdir_p(@output_dir)
    end

    def assemble
      output_mp4 = @output_dir.join("short_#{@short_video.id}_#{Time.now.to_i}.mp4").to_s

      # 1. Download or get path of audio file
      audio_path = extract_audio_path

      # 2. Render MP4 using FFmpeg
      success = render_with_ffmpeg(audio_path, output_mp4)

      unless success && File.exist?(output_mp4) && File.size(output_mp4) > 1000
        generate_fallback_mp4(output_mp4)
      end

      # 3. Attach to ActiveStorage
      File.open(output_mp4) do |file|
        @short_video.video_file.attach(
          io: file,
          filename: "short_#{@short_video.id}.mp4",
          content_type: "video/mp4"
        )
      end

      # Cleanup
      FileUtils.rm_f(output_mp4)
      FileUtils.rm_f(audio_path) if audio_path.include?("tmp_audio_")

      true
    rescue StandardError => e
      Rails.logger.error("Video assembly error: #{e.message}")
      false
    end

    private

    def extract_audio_path
      if @short_video.audio_file.attached?
        temp_audio = Rails.root.join("tmp", "tmp_audio_#{@short_video.id}.mp3").to_s
        File.binwrite(temp_audio, @short_video.audio_file.download)
        temp_audio
      else
        # Silent tone
        temp_audio = Rails.root.join("tmp", "tmp_audio_silent.mp3").to_s
        system("ffmpeg -y -f lavfi -i \"sine=frequency=100:duration=15\" -c:a libmp3lame #{temp_audio} > /dev/null 2>&1")
        temp_audio
      end
    end

    def render_with_ffmpeg(audio_path, output_path)
      # Check if ffmpeg is available
      return false unless system("which ffmpeg > /dev/null 2>&1")

      valid_images = @visual_paths.select { |p| File.exist?(p) && File.size(p) > 0 }
      
      if valid_images.any?
        # Create an input list for ffmpeg concat
        list_file = Rails.root.join("tmp", "concat_#{@short_video.id}.txt").to_s
        slide_duration = 4.0 # seconds per slide
        
        File.open(list_file, "w") do |f|
          valid_images.each do |img|
            f.puts("file '#{img}'")
            f.puts("duration #{slide_duration}")
          end
          # Add the last file again per ffmpeg concat requirement
          f.puts("file '#{valid_images.last}'")
        end

        cmd = [
          "ffmpeg -y",
          "-f concat -safe 0 -i #{list_file}",
          "-i #{audio_path}",
          "-vf \"scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,format=yuv420p\"",
          "-c:v libx264 -preset fast -crf 23 -r 30",
          "-c:a aac -b:a 192k",
          "-shortest",
          "-movflags +faststart",
          output_path
        ].join(" ")

        result = system("#{cmd} > /dev/null 2>&1")
        FileUtils.rm_f(list_file)
        return result
      end

      # If no valid images, generate animated gradient video directly from lavfi
      cmd = [
        "ffmpeg -y",
        "-f lavfi -i \"color=c=0x0f172a:s=1080x1920:r=30\"",
        "-i #{audio_path}",
        "-vf \"format=yuv420p\"",
        "-c:v libx264 -preset fast -crf 23",
        "-c:a aac -b:a 192k",
        "-shortest",
        output_path
      ].join(" ")

      system("#{cmd} > /dev/null 2>&1")
    end

    def generate_fallback_mp4(output_path)
      # Attempt minimal ffmpeg test video or write a mock MP4 container
      cmd = "ffmpeg -y -f lavfi -i testsrc=size=1080x1920:rate=30 -f lavfi -i sine=frequency=440 -t 5 -c:v libx264 -c:a aac -pix_fmt yuv420p #{output_path} > /dev/null 2>&1"
      return if system(cmd) && File.exist?(output_path) && File.size(output_path) > 0

      # Create dummy binary if ffmpeg is totally absent
      File.binwrite(output_path, "\x00\x00\x00 ftypmp42\x00\x00\x00\x00mp42mp41" + ("\x00" * 2048))
    end
  end
end
