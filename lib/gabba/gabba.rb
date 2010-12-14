# yo, easy server-side tracking for Google Analytics... hey!
require "uri"
require "net/http"
require 'cgi'
require 'ipaddr'
require 'active_support/core_ext/array/extract_options'

module Gabba

  class GoogleAnalyticsSetupError < RuntimeError; end
  class GoogleAnalyticsNetworkError < RuntimeError; end

  class Gabba
    GOOGLE_HOST = "www.google-analytics.com"
    BEACON_PATH = "/__utm.gif"
    USER_AGENT = "Gabba #{VERSION} Agent"

    attr_accessor :utmwv, :utmn, :utmhn, :utmcs, :utmul, :utmp, :utmac, :utmt, :utmcc, :utmr, :utmip, :user_agent

    # create with:
    #  ga_acct, domain
    # or
    #  ga_acct, :request => request
    def initialize(ga_acct, *args)
      @utmwv = "4.4sh" # GA version
      @utmcs = "UTF-8" # charset
      @utmul = "en-us" # language
      @utmn = rand(8999999999) + 1000000000
      @user_agent = Gabba::USER_AGENT

      @utmac = ga_acct
      opts = args.extract_options!
      @utmhn = args.shift
      opts.each {|key, value| self.send("#{key}=", value) }
    end

    def request=(request)
      @user_agent = request.env["HTTP_USER_AGENT"] || Gabba::USER_AGENT
      @utmhn ||= request.env["SERVER_NAME"] || ""
      @utmr = request.params['utmr'].blank? ? (request.env['HTTP_REFERER'].blank? ? "-" : request.env['HTTP_REFERER']) : request.params[:utmr]
      @utmp = request.params['utmp'].blank? ? (request.env['REQUEST_URI'] || "") : request.params['utmp']
      # the last octect of the IP address is removed to anonymize the user.
      @utmip = IPAddr.new(request.env["REMOTE_ADDR"]).mask(24).to_s
    end

    # parameters:
    #  title, page, :utmvid => visitor_id
    # or
    #  title, :utmvid => visitor_id
    # if page is obmitted, it is taken from the request
    def page_view(title, *args)
      check_account_params
      opts = args.extract_options!
      opts[:utmdt] = title
      opts[:utmp] = args.shift || @utmp
      hey(opts)
    end

    # parameters:
    #  category, action, label = nil, value = nil, :utmvid => visitor_id
    def event(*args)
      check_account_params
      opts = args.extract_options!
      opts[:utmt] = 'event'
      opts[:utme] = event_data(*args)
      hey(opts)
    end

    private

    def default_params
      { :utmwv => @utmwv,
        :utmn => @utmn,
        :utmhn => @utmhn,
        :utmcs => @utmcs,
        :utmul => @utmul,
        :utmhid => rand(8999999999) + 1000000000,
        :utmac => @utmac,
        :utmcc => @utmcc || cookie_params,
        :utmr => @utmr,
        :utmp => @utmp,
        :utmip => @utmip }
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
      raise GoogleAnalyticsSetupError, "no account" unless @utmac
      raise GoogleAnalyticsSetupError, "no domain" unless @utmhn
    end

    # makes the tracking call to Google Analytics
    def hey(params)
      headers = {"User-Agent" => URI.escape(user_agent)}
      params = default_params.merge(params).reject{|k,v| v.blank? }
      query = params.map {|k,v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')
      req = Net::HTTP::Get.new("#{BEACON_PATH}?#{query}", headers)
      res = Net::HTTP.start(GOOGLE_HOST) do |http|
        http.request(req)
      end
      raise GoogleAnalyticsNetworkError unless res.code == "200"
    end
  end
end
