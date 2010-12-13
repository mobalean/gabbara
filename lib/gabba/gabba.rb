# yo, easy server-side tracking for Google Analytics... hey!
require "uri"
require "net/http"
require 'cgi'

module Gabba

  class NoGoogleAnalyticsAccountError < RuntimeError; end
  class NoGoogleAnalyticsDomainError < RuntimeError; end
  class GoogleAnalyticsNetworkError < RuntimeError; end

  class Gabba
    GOOGLE_HOST = "http://www.google-analytics.com"
    BEACON_PATH = "/__utm.gif"
    USER_AGENT = "Gabba #{VERSION} Agent"

    attr_accessor :utmwv, :utmn, :utmhn, :utmcs, :utmul, :utmdt, :utmp, :utmac, :utmt, :utmcc, :user_agent

    def initialize(ga_acct, domain, agent = Gabba::USER_AGENT)
      @utmwv = "4.4sh" # GA version
      @utmcs = "UTF-8" # charset
      @utmul = "en-us" # language

      @utmn = rand(8999999999) + 1000000000
      @utmhid = rand(8999999999) + 1000000000

      @utmac = ga_acct
      @utmhn = domain
      @user_agent = agent
    end

    def page_view(title, page, utmhid = rand(8999999999) + 1000000000)
      check_account_params
      hey(page_view_params(title, page, utmhid))
    end

    def event(category, action, label = nil, value = nil, utmhid = rand(8999999999) + 1000000000)
      check_account_params
      hey(event_params(category, action, label, value, utmhid))
    end

    private

    def page_view_params(title, page, utmhid)
      { :utmwv => @utmwv,
        :utmn => @utmn,
        :utmhn => @utmhn,
        :utmcs => @utmcs,
        :utmul => @utmul,
        :utmdt => title,
        :utmhid => utmhid,
        :utmp => page,
        :utmac => @utmac,
        :utmcc => @utmcc || cookie_params }
    end

    def event_params(category, action, label, value, utmhid)
      { :utmwv => @utmwv,
        :utmn => @utmn,
        :utmhn => @utmhn,
        :utmt => 'event',
        :utme => event_data(category, action, label, value),
        :utmcs => @utmcs,
        :utmul => @utmul,
        :utmhid => utmhid,
        :utmac => @utmac,
        :utmcc => @utmcc || cookie_params }
    end

    def event_data(category, action, label = nil, value = nil)
      data = "5(#{category}*action" + (label ? "*#{label})" : ")")
      data += "(#{value})" if value
    end

    # create magical cookie params used by GA for its own nefarious purposes
    def cookie_params(utma1 = rand(89999999) + 10000000, utma2 = rand(1147483647) + 1000000000, today = Time.now)
      "__utma=1.#{utma1}00145214523.#{utma2}.#{today.to_i}.#{today.to_i}.15;+__utmz=1.#{today.to_i}.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none);"
    end

    # sanity check that we have needed params to even call GA
    def check_account_params
      raise NoGoogleAnalyticsAccountError unless @utmac
      raise NoGoogleAnalyticsDomainError unless @utmhn
    end

    # makes the tracking call to Google Analytics
    def hey(params, referer = "-")
      headers = {"User-Agent" => URI.escape(user_agent)}
      req = Net::HTTP::Get.new("#{BEACON_PATH}?#{hash_to_querystring(params)}", headers)
      res = Net::HTTP.start(GOOGLE_HOST) do |http|
        http.request(req)
      end
      raise GoogleAnalyticsNetworkError unless res.code == "200"
    end

    # convert params hash to query string
    def hash_to_querystring(hash = {})
      hash.map {|key, value| "#{key.to_s}=#{CGI.escape(value.to_s)}" }.join('&')
    end
  end
end
