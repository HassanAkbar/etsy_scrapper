require "date"
require "json"
require 'kimurai'

class EtsyScrapper < Kimurai::Base
  @name = "etsy_scrapper"
  @engine = :selenium_chrome
  @start_urls = ["https://www.etsy.com/shop/DanisCustomCrafts?ref=seller-platform-mcnav"]

  def parse(response, url:, data: {})
    review_page_count = 3
    review_page_number = 2

    scrapped_data = {
      seller_name: response.css(".shop-name-and-title-container > h1").text.strip,
      description: response.css(".shop-name-and-title-container > p").text.strip,
      logo_url: response.css(".shop-icon > img").attr("src").value,
      rating: response.css(".reviews-link-shop-info > span > span > span.wt-screen-reader-only").text.split.first.to_f,
      review_count: response.css(".reviews-total > .clearfix").children[-2].text.strip.gsub(/\(|\)/, "").to_i
    }

    reviewes = []
    reviewes += parse_reviewes(response)

    (2..review_page_count).each do |page|
      browser.find(:xpath, "//li//a[contains(@class, 'page-#{page}')]").click rescue break
      sleep(5)

      reviewes += parse_reviewes(browser.current_response)
    end

    scrapped_data[:reviewes] = reviewes

    save_to "results.json", scrapped_data, format: :pretty_json
  end

  def parse_reviewes(response)
    reviewes = []
    response.css(".reviews-list > li").each do |review|
      review_date = review.css(".review-item > .flag > .flag-body > div > .shop2-review-attribution").text.strip.split.last(3).join(" ")

      reviewes << {
        reviewer_name: review.css(".review-item > .flag > .flag-body > div > .shop2-review-attribution > a").text.strip,
        review_text: review.css(".review-item > .flag > .flag-body > div > .prose.break-word").text.strip,
        review_date: Date.parse(review_date).strftime("%Y-%m-%d"),
        rating: review.css(".review-item > .flag > .flag-body > div > span.stars-svg > span.screen-reader-only").text.split.first.to_f,
        profile_picture_url: review.css(".review-item > .flag > .flag-img > img").attr('data-src')&.value
      }
    end

    reviewes
  end
end

EtsyScrapper.crawl!
