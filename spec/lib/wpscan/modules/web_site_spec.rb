#--
# WPScan - WordPress Security Scanner
# Copyright (C) 2012
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

shared_examples_for "WebSite" do
  let(:fixtures_dir) { SPEC_FIXTURES_WPSCAN_MODULES_DIR + "/web_site" }

  before :each do
    @module = WpScanModuleSpec.new("http://example.localhost/")
    @module.extend(WebSite)
  end

  describe "#login_url" do
    it "should return the correct url : http://example.localhost/wp-login.php" do
      @module.login_url.should === "http://example.localhost/wp-login.php"
    end
  end

  describe "#xml_rpc_url" do
    it "should return the correct url : http://example.localhost/xmlrpc.php" do
      xmlrpc = "http://example.localhost/xmlrpc.php"
      stub_request(:get, "http://example.localhost/").
          to_return(:status => 200, :body => "", :headers => { "X-Pingback" => xmlrpc})
      @module.xml_rpc_url.should === xmlrpc
    end

    it "should return nil" do
      stub_request(:get, "http://example.localhost/").to_return(:status => 200)
      @module.xml_rpc_url.should be_nil
    end
  end

  describe "#has_xml_rpc?" do
    it "should return true" do
      stub_request(:get, "http://example.localhost/").
          to_return(:status => 200, :body => "", :headers => { "X-Pingback" => "xmlrpc"})
      @module.has_xml_rpc?.should be_true
    end

    it "should return false" do
      stub_request(:get, "http://example.localhost/").to_return(:status => 200)
      @module.has_xml_rpc?.should be_false
    end
  end

  describe "#is_wordpress?" do
    # each url (wp-login and xmlrpc) pointed to a 404
    before :each do
      stub_request(:get, @module.uri.to_s).
          to_return(:status => 200, :body => "", :headers => { "X-Pingback" => @module.uri.merge("xmlrpc.php")})
      [@module.login_url, @module.xml_rpc_url].each do |url|
        stub_request(:get, url).to_return(:status => 404, :body => "")
      end
    end

    it "should return false if both files are not found (404)" do
      @module.is_wordpress?.should be_false
    end

    it "should return true if the wp-login is found and is a valid wordpress one" do
      stub_request(:get, @module.login_url).
          to_return(:status => 200, :body => File.new(fixtures_dir + "/wp-login.php"))

      @module.is_wordpress?.should be_true
    end

    it "should return true if the xmlrpc is found" do
      stub_request(:get, @module.xml_rpc_url).
        to_return(:status => 200, :body => File.new(fixtures_dir + "/xmlrpc.php"))

      @module.is_wordpress?.should be_true
    end
  end

  describe "#is_online?" do
    it "should return false" do
      stub_request(:get, @module.url).to_return(:status => 0)
      @module.is_online?.should be_false
    end

    it "should return true" do
      stub_request(:get, @module.url).to_return(:status => 200)
      @module.is_online?.should be_true
    end
  end

  describe "#has_basic_auth?" do
    it "should detect that the wpsite is basic auth protected" do
      stub_request(:get, "http://example.localhost/").to_return(:status => 401)
      @module.should have_basic_auth
    end

    it "should not have a basic auth for a 200" do
      stub_request(:get, "http://example.localhost/").to_return(:status => 200)
      @module.should_not have_basic_auth
    end
  end

  describe "#redirection" do
    it "should return nil if no redirection detected" do
      stub_request(:get, @module.url).to_return(:status => 200, :body => '')

      @module.redirection.should be_nil
    end

    [301, 302].each do |status_code|
      it "should return http://new-location.com if the status code is #{status_code}" do
        stub_request(:get, @module.url).
            to_return(:status => status_code, :headers => {:location => "http://new-location.com"})

        @module.redirection.should === "http://new-location.com"
      end
    end
  end

end
