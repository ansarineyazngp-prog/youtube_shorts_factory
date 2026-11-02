# frozen_string_literal: true

puts "== Seeding YouTube Shorts Factory =="

# 1. Default YouTube Channel Settings
account = YoutubeAccount.first_or_create!(
  channel_title: "Curiosity Labs Shorts",
  auto_approve_default: false,
  notification_type: "discord"
)
puts "  ✓ YouTube Account record initialized"

# 2. Sample Published Video
ShortVideo.where(topic: "The Pratfall Effect: Why Flaws Make You Likable").first_or_create!(
  category: "Psychology",
  status: :published,
  auto_publish: false,
  title: "Why People Like You MORE When You Make Mistakes 😱 #Shorts",
  description: "Ever dropped a coffee cup in public and died of embarrassment? Psychology shows it actually makes people like you more! Discover the Pratfall Effect. #Shorts #Psychology #Viral",
  script_text: "Did you know that making a clumsy mistake in public actually makes people like you MORE? Psychologists call this the Pratfall Effect. When someone who is competent makes a small blunder, it makes them feel relatable and human. So the next time you trip, don't worry—you just became 20% more attractive! Subscribe for more mind-bending human secrets.",
  tags: "Shorts, Psychology, Facts, Viral, LifeHacks",
  youtube_video_id: "demo_shorts_77",
  youtube_url: "https://youtube.com/shorts/demo_shorts_77",
  published_at: 2.hours.ago
)
puts "  ✓ Sample Published Video created"

# 3. Sample Video Ready for Review
ShortVideo.where(topic: "What Happens If You Fall Into The Mariana Trench?").first_or_create!(
  category: "Space & Science",
  status: :ready_for_review,
  auto_publish: false,
  title: "Falling 36,000 Feet Under the Ocean 🌊 #Shorts",
  description: "The Mariana Trench is deeper than Mount Everest is tall. Here is what would happen to the human body at the bottom of the world. #Shorts #Ocean #Science",
  script_text: "What if you fell into the Mariana Trench? At 36,000 feet deep, the water pressure is over 1,000 times higher than sea level—equivalent to having 100 adult elephants standing on your head! In total darkness, water temperature is near freezing, yet alien hydrothermal vents spew toxic water at 700 degrees Fahrenheit. Would you dare dive here? Tell us below!",
  tags: "Shorts, Ocean, Science, MarianaTrench, DeepSea",
  created_at: 30.minutes.ago
)
puts "  ✓ Sample Ready-for-Review Video created"

# 4. Queued Draft Topics
[
  { topic: "The 3 Subtle Signs Someone is Lying to You (FBI Technique)", category: "Psychology" },
  { topic: "How a Single Pigeon Saved 194 Soldiers in World War 1", category: "History Mysteries" },
  { topic: "Quantum Computers: Breaking Modern Encryption in 30 Seconds", category: "Tech & AI" }
].each do |item|
  ShortVideo.where(topic: item[:topic]).first_or_create!(
    category: item[:category],
    status: :draft,
    auto_publish: false
  )
end
puts "  ✓ Queued Draft Topics created"

puts "== Seeding Complete! Ready to launch =="
