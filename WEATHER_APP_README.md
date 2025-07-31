# Weather App Documentation

> **This document describes the Rails weather application used in the [Rails 8 + Kamal + AWS EC2 Deployment Tutorial](README.md). For deployment instructions, see the main [README.md](README.md).**

## Weather App Overview

* Overview
  * This is a simple app that uses google places autocomplete to take an address entry and queries www.weatherapi.com 
  to present a 7 day forecast.  Forecast data from the API is cached by US Zip Code for 30 minutes using Rails memory caching. 
  There is a thermometer icon in the "Current Conditions" header section that indicates whether the forecast data is 
  cached or fresh. A full thermometer icon means cached, a low thermometer icon means freshly updated.

* Key Features
  * **Google Places Autocomplete**: Smart address/location input with autocomplete suggestions
  * **Weather API Integration**: 7-day forecast data from WeatherAPI.com
  * **Intelligent Caching**: 30-minute cache by zip code to reduce API calls and improve performance
  * **Cache Status Indicator**: Visual thermometer icon shows if data is cached or freshly fetched
  * **Temperature Unit Toggle**: Switch between Fahrenheit and Celsius
  * **Responsive Design**: Bootstrap 5.3 for mobile-friendly interface
  * **AJAX Interface**: Seamless updates without page refreshes

* Technical Architecture
  * **Rails 8.0**: Latest Rails framework with modern conventions
  * **Stimulus Controllers**: Hotwire Stimulus for JavaScript interactions
  * **Typhoeus HTTP Client**: High-performance HTTP requests for API calls
  * **Custom Error Handling**: Graceful handling of API failures and invalid inputs
  * **Comprehensive Testing**: RSpec, Webmock, Capybara, and Cypress test coverage


* Requirements
  * Ruby 3.4.2
  * Rails 8.02
  * SQLite3
  * jQuery 3.7.1
  * Bootstrap 5.3
  * Bundler

* Clone:
  * `git clone https://github.com/worshamweb/rails8-kamal-aws-tutorial.git`
  * cd rails8-kamal-aws-tutorial
  * bundle install
  * rails db:prepare
  * rails s
  * http://localhost:3000/forecast/

* Testing
  * This app uses Rspec, Webmock, Capybara Selenium Drivers and Cypress
  * run `rspec spec` for tests
  * default configuration is selenium headless driver. To change, edit `Capybara.default_driver = :selenium_chrome_headless`
  in `spec/rails_helper.rb`

* Troubleshooting
  * App uses memory cache by default. To enable SSD caching:
    * Change `config.cache_store = :memory_store` to `config.cache_store = :solid_cache_store` in `config/environments/development.rb`
    * Run `./bin/rails db:setup:cache` to create cache database
  
