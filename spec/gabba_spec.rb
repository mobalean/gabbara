require File.dirname(__FILE__) + '/spec_helper'

describe Gabbara::Gabba do

  describe "parameter checking" do
    it "must require GA account for page_view" do
      expect {Gabbara::Gabba.new(nil, nil).page_view("thing", "thing")}.to raise_error(Gabbara::GoogleAnalyticsSetupError)
    end
    it "must require GA domain for page_view" do
      expect {Gabbara::Gabba.new("abs", nil).page_view("thing", "thing")}.to raise_error(Gabbara::GoogleAnalyticsSetupError)
    end
    it "must require GA account for event" do
      expect {Gabbara::Gabba.new(nil, nil).event("cat1", "act1", "lab1", "val1")}.to raise_error(Gabbara::GoogleAnalyticsSetupError)
    end
    it "must require GA domain for event" do
      expect {Gabbara::Gabba.new("abs", nil).event("cat1", "act1", "lab1", "val1")}.to raise_error(Gabbara::GoogleAnalyticsSetupError)
    end
  end

  describe "when tracking page views" do
    before do
      stub_analytics "utmdt"=>"title", "utmp"=>"/page/path"
      @gabba = Gabbara::Gabba.new("UC-123", "domain", :utmn => "1009731272", :utmcc => '')
    end

    it "must do a request to google" do
      @gabba.page_view("title", "/page/path", :utmhid => "6783939397")
    end
  end

  describe "when tracking page views from request" do
    before do
      stub_analytics "DoCoMo", "utmdt"=>"title", "utmhn"=>"test.local", "utmp"=>"/test", "utmip"=>"127.0.0.0", "utmr"=>"-"
      @gabba = Gabbara::Gabba.new("UC-123", :request => test_request, :utmn => "1009731272", :utmcc => '')
    end

    it "must to a request to google" do
      @gabba.page_view("title", :utmhid => "6783939397")
    end
  end

  describe "when tracking page views from request with visitor_id" do
    before do
      stub_analytics "DoCoMo", "utmdt"=>"title", "utmhn"=>"test.local", "utmp"=>"/test", "utmip"=>"127.0.0.0", "utmr"=>"-", "utmvid" => "0x16741532543"
      @gabba = Gabbara::Gabba.new("UC-123", :request => test_request, :utmn => "1009731272", :utmcc => '')
    end

    it "must to a request to google" do
      @gabba.page_view("title", :utmhid => "6783939397", :utmvid => "0x16741532543")
    end
  end

  describe "when tracking custom events with two params" do
    before do
      stub_analytics "utme"=>"5(cat1*act1)", "utmt"=>"event"
      @gabba = Gabbara::Gabba.new("UC-123", "domain", :utmn => "1009731272", :utmcc => '')
    end

    it "must do a request to google" do
      @gabba.event("cat1", "act1", :utmhid => "6783939397")
    end
  end

  describe "when tracking custom events with label without value" do
    before do
      stub_analytics "utme"=>"5(cat1*act1*lab1)", "utmt"=>"event"
      @gabba = Gabbara::Gabba.new("UC-123", "domain", :utmn => "1009731272", :utmcc => '')
    end

    it "must do a request to google" do
      @gabba.event("cat1", "act1", "lab1", :utmhid => "6783939397")
    end
  end

  describe "when tracking custom events with value without label" do
    before do
      stub_analytics "utme"=>"5(cat1*act1)(val1)", "utmt"=>"event"
      @gabba = Gabbara::Gabba.new("UC-123", "domain", :utmn => "1009731272", :utmcc => '')
    end

    it "must do a request to google" do
      @gabba.event("cat1", "act1", nil, "val1", :utmhid => "6783939397")
    end
  end

  describe "when tracking custom events with all params" do
    before do
      stub_analytics "utme"=>"5(cat1*act1*lab1)(val1)", "utmt"=>"event"
      @gabba = Gabbara::Gabba.new("UC-123", "domain", :utmn => "1009731272", :utmcc => '')
    end

    it "must do a request to google" do
      @gabba.event("cat1", "act1", "lab1", "val1", :utmhid => "6783939397")
    end
  end

  def stub_analytics(*args)
    expected_params = args.extract_options!
    user_agent = args.shift || "Gabbara%20#{Gabbara::VERSION}%20Agent"
    expected_params = { "utmac"=>"UC-123", "utmcs"=>"UTF-8", "utmhid"=>"6783939397", "utmhn"=>"domain", "utmn"=>"1009731272", "utmul"=>"en-us", "utmwv"=>"4.4sh" }.merge(expected_params).reject{|k,v| v.blank? }
    query = expected_params.map {|k,v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')
    s = stub_request(:get, "http://www.google-analytics.com:80/__utm.gif?#{query}").
      with(:headers => {'Accept'=>'*/*', 'User-Agent'=>user_agent}).
      to_return(:status => 200, :body => "", :headers => {})
    #puts s.request_pattern
  end

  def test_request(params = {})
    params = {"REMOTE_ADDR" => "127.0.0.1", "HTTP_USER_AGENT" => "DoCoMo"}.merge(params)
    Rack::Request.new(Rack::MockRequest.env_for("http://test.local/utm.gif?utmp=/test", params))
  end

end
