require File.dirname(__FILE__) + '/spec_helper'

describe Gabba::Gabba do

  describe "parameter checking" do
    it "must require GA account for page_view" do
      expect {Gabba::Gabba.new(nil, nil).page_view("thing", "thing")}.to raise_error(Gabba::NoGoogleAnalyticsAccountError)
    end
    it "must require GA domain for page_view" do
      expect {Gabba::Gabba.new("abs", nil).page_view("thing", "thing")}.to raise_error(Gabba::NoGoogleAnalyticsDomainError)
    end
    it "must require GA account for event" do
      expect {Gabba::Gabba.new(nil, nil).event("cat1", "act1", "lab1", "val1")}.to raise_error(Gabba::NoGoogleAnalyticsAccountError)
    end
    it "must require GA domain for event" do
      expect {Gabba::Gabba.new("abs", nil).event("cat1", "act1", "lab1", "val1")}.to raise_error(Gabba::NoGoogleAnalyticsDomainError)
    end
  end

  describe "when tracking page views" do
    before do
      stub_analytics "utmac=abc&utmcc=&utmcs=UTF-8&utmdt=title&utmhid=6783939397&utmhn=123&utmn=1009731272&utmp=/page/path&utmul=en-us&utmwv=4.4sh"

      @gabba = Gabba::Gabba.new("abc", "123")
      @gabba.utmn = "1009731272"
      @gabba.utmcc = ''
    end

    it "must do a request to google" do
      @gabba.page_view("title", "/page/path", "6783939397")
    end
  end

  describe "when tracking custom events" do
    before do
      stub_analytics "utmac=abc&utmcc=&utmcs=UTF-8&utme=5(cat1*action*lab1)(val1)&utmhid=6783939397&utmhn=123&utmn=1009731272&utmt=event&utmul=en-us&utmwv=4.4sh"

      @gabba = Gabba::Gabba.new("abc", "123")
      @gabba.utmn = "1009731272"
      @gabba.utmcc = ''
    end

    it "must do a request to google" do
      @gabba.event("cat1", "act1", "lab1", "val1", "6783939397")
    end
  end

  def stub_analytics(expected_params)
    stub_request(:get, "http://http//www.google-analytics.com:80/__utm.gif?#{expected_params}").
      with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Gabba%200.0.1%20Agent'}).
      to_return(:status => 200, :body => "", :headers => {})
  end
end
