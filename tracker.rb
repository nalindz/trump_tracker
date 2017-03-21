require 'nokogiri'
require 'open-uri'
require 'twitter'


# uses the cnn rss feed to grab the latest stories
CNN_NEWS_URL = "http://rss.cnn.com/rss/cnn_latest.rss"

# required for twitter API - this is a throwaway account. should be in a config file and encrypted / secret ideally
TWITTER_CONSUMER_KEY = "zfGJYp2AeNxbmq22A58OQwLuM"
TWITTER_CONSUMER_SECRET = "Fmt3E1X5mI4qRSwZ9Gsv1g5I0DC0CKKbm352fuuYZCIV4ci2Ad"


# gets the body text of a given CNN story
def getCNNStoryBody(link)
  doc = Nokogiri::HTML(open(link))
  
  # CNN has two different formats of HTML for their stories. If one method doesn't work a fall back
  # method is used
  story_body = doc.css('.zn-body__paragraph').map { |body| body.content }.join("<br/><br/>")
  if story_body.empty?
    story_body = doc.css('#storytext').css('p').map { |body| body.content }.join("<br/><br/>")
  end
  story_body
end

# grabs a maximum of 25 CNN news stories from the latest RSS feed
def getTrumpCNNStories
  stories = []
  doc = Nokogiri::XML(open(CNN_NEWS_URL))
  doc.xpath('//item/title').each do |title| 
    break if stories.length > 25
    if title.content.downcase.include? "trump"
      link = title.parent.css('link').first.content
      stories << {title: title.content, 
                  link: link,
                  body: getCNNStoryBody(link)}
    end
  end
  stories
end

# grabs the latest 25 tweets from Trump's twitter page
def getTrumpTweets
  stories = []

  twitter = Twitter::REST::Client.new do |config|
    config.consumer_key        = TWITTER_CONSUMER_KEY
    config.consumer_secret     = TWITTER_CONSUMER_SECRET
  end

  twitter.user_timeline("realDonaldTrump", {count: 25}).each do |tweet|
    stories << {title: tweet.full_text,
                link: tweet.uri,
                body: tweet.full_text}
  end
  stories
end

# method used to render the stories from an array to html
def renderStories(stories)

  # header information used for javascript and CSS
  output = '<html><head><script src="http://code.jquery.com/jquery-3.2.1.slim.min.js" integrity="sha256-k2WSCIexGzOj3Euiig+TlR8gA0EmPjuc79OEeY5L45g="   crossorigin="anonymous"></script><script src="https://cdn.jsdelivr.net/semantic-ui/2.2.9/semantic.min.js"></script><link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/semantic-ui/2.2.9/semantic.min.css"/>
  </head><body>'

  output += '<div style="padding-top: 50px;" class="ui one column stackable center page grid">'
  output += "<h2 class='ui header column'>Trump Tracker</h2>"

  # renders each story as a title with collapsable body
  stories.each_with_index do |story, i|
    output += "<h3 class='ui header column' onClick='$(\"\##{i}\").toggle()'>#{story[:title]}</h3><div class='ui segment' id=#{i} style='display:none'>#{story[:body]}<br/><br/>Link: <a href='#{story[:link]}'>#{story[:link]}</a></div>"
  end

  output += "</div>"
  output += "</body></html>"
end

# gets both CNN and tweets before rendering
all_stories = getTrumpCNNStories + getTrumpTweets

# renders stories and outputs to file
File.open("trump.html", 'w') { |file| file.write(renderStories(all_stories)) }
