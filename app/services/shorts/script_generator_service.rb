# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Shorts
  class ScriptGeneratorService
    def self.generate_for(short_video)
      new(short_video).generate
    end

    def initialize(short_video)
      @short_video = short_video
    end

    def generate
      result = if ENV["GEMINI_API_KEY"].present?
                 generate_with_gemini
               elsif ENV["OPENAI_API_KEY"].present?
                 generate_with_openai
               else
                 generate_template_script
               end

      @short_video.update!(
        title: result[:title],
        script_text: result[:script_text],
        description: result[:description],
        tags: result[:tags].join(", "),
        metadata: (@short_video.metadata.present? ? JSON.parse(@short_video.metadata) : {}).merge({
          scenes: result[:scenes],
          generated_by: result[:engine]
        }).to_json
      )

      result
    end

    private

    def generate_with_gemini
      api_key = ENV["GEMINI_API_KEY"]
      url = URI("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=#{api_key}")

      prompt = <<~PROMPT
        You are a world-class viral YouTube Shorts scriptwriter and YouTube algorithm expert.
        Write a high-retention 35-45 second vertical short video package for the topic: "#{@short_video.topic}".
        Return ONLY valid JSON matching this exact structure:
        {
          "title": "Viral Hook Title Under 55 Chars #Shorts",
          "script_text": "Complete natural spoken voice narration script. Start with an irresistible 3-second psychological hook. Include 2-3 fascinating facts. End with a strong engagement question.",
          "description": "Engaging description explaining the topic, key timestamps or takeaways, followed by 5-8 relevant hashtags including #Shorts #Viral.",
          "tags": ["Shorts", "Facts", "DidYouKnow", "Science", "Curiosity"],
          "scenes": [
            { "timestamp": "0:00-0:05", "visual_prompt": "Cinematic visual description for AI image generation", "caption": "Hook text" },
            { "timestamp": "0:05-0:15", "visual_prompt": "Cinematic visual description for scene 2", "caption": "Key fact 1" },
            { "timestamp": "0:15-0:25", "visual_prompt": "Cinematic visual description for scene 3", "caption": "Key fact 2" },
            { "timestamp": "0:25-0:35", "visual_prompt": "Cinematic visual description for conclusion", "caption": "Question text" }
          ]
        }
      PROMPT

      req = Net::HTTP::Post.new(url, "Content-Type" => "application/json")
      req.body = {
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { responseMimeType: "application/json" }
      }.to_json

      res = Net::HTTP.start(url.hostname, url.port, use_ssl: true, open_timeout: 10, read_timeout: 25) do |http|
        http.request(req)
      end

      if res.is_a?(Net::HTTPSuccess)
        data = JSON.parse(res.body)
        raw_json = data.dig("candidates", 0, "content", "parts", 0, "text")
        parsed = JSON.parse(raw_json)
        return format_payload(parsed, "gemini-1.5-flash")
      end

      generate_template_script
    rescue StandardError => e
      Rails.logger.error("Gemini script generation failed: #{e.message}")
      generate_template_script
    end

    def generate_with_openai
      api_key = ENV["OPENAI_API_KEY"]
      url = URI("https://api.openai.com/v1/chat/completions")

      req = Net::HTTP::Post.new(url, {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{api_key}"
      })

      prompt = "Generate a viral YouTube Shorts script for '#{@short_video.topic}' in JSON format with title, script_text, description, tags array, and scenes array."

      req.body = {
        model: "gpt-4o-mini",
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: "You are an elite YouTube Shorts scriptwriter who returns clean JSON." },
          { role: "user", content: prompt }
        ],
        temperature: 0.7
      }.to_json

      res = Net::HTTP.start(url.hostname, url.port, use_ssl: true, open_timeout: 10, read_timeout: 25) do |http|
        http.request(req)
      end

      if res.is_a?(Net::HTTPSuccess)
        data = JSON.parse(res.body)
        parsed = JSON.parse(data.dig("choices", 0, "message", "content"))
        return format_payload(parsed, "gpt-4o-mini")
      end

      generate_template_script
    rescue StandardError => e
      Rails.logger.error("OpenAI script generation failed: #{e.message}")
      generate_template_script
    end

    def generate_template_script
      topic = @short_video.topic
      clean_title = "#{topic.truncate(45)} 😱 #Shorts"
      script = <<~SCRIPT.strip
        Did you know this shocking truth about #{topic}?
        Most people have no idea, but scientific studies reveal something fascinating.
        When you look deeper into this phenomenon, the reality is completely unexpected.
        It completely changes how you understand the world around you.
        Have you ever experienced this yourself? Tell me in the comments, and subscribe for more mind-blowing daily facts!
      SCRIPT

      desc = <<~DESC.strip
        Discover the mind-blowing truth about #{topic}! 
        In this short, we break down the most fascinating secrets and facts that will completely change your perspective.

        🔔 Subscribe to the channel for daily curiosity boosters!
        
        #Shorts #Viral #Facts #MindBlowing #Curiosity #Trending
      DESC

      format_payload({
        "title" => clean_title,
        "script_text" => script,
        "description" => desc,
        "tags" => ["Shorts", "Facts", "DidYouKnow", "Viral", "Mindset", "Knowledge"],
        "scenes" => [
          { "timestamp" => "0:00-0:08", "visual_prompt" => "Dramatic dark cinematic portrait representing #{topic}", "caption" => "Did you know this truth?" },
          { "timestamp" => "0:08-0:18", "visual_prompt" => "Hyperrealistic visual details explaining #{topic}", "caption" => "The hidden reality revealed" },
          { "timestamp" => "0:18-0:30", "visual_prompt" => "Futuristic glowing scientific visualization", "caption" => "Science proves it" },
          { "timestamp" => "0:30-0:40", "visual_prompt" => "Engaging cinematic typography asking question", "caption" => "Comment your thoughts below!" }
        ]
      }, "template_engine")
    end

    def format_payload(data, engine)
      {
        title: data["title"] || "#{@short_video.topic} #Shorts",
        script_text: data["script_text"] || "Check out this incredible fact about #{@short_video.topic}",
        description: data["description"] || "Daily shorts facts on #{@short_video.topic}. #Shorts",
        tags: Array(data["tags"] || ["Shorts", "Facts"]),
        scenes: data["scenes"] || [],
        engine: engine
      }
    end
  end
end
