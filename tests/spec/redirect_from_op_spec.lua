local http = require("socket.http")
local test_support = require("test_support")
require 'busted.runner'()

describe("when a redirect is received", function()
  test_support.start_server()
  teardown(test_support.stop_server)
  local _, _, headers = http.request({
    url = "http://localhost/default/t",
    redirect = false
  })
  local state = test_support.grab(headers, 'state')
  test_support.register_nonce(headers)
  local cookie_header = test_support.extract_cookies(headers)
  describe("without an active user session", function()
    local _, redirStatus = http.request({
          url = "http://localhost/default/redirect_uri?code=foo&state=" .. state,
    })
    it("should be rejected", function()
       assert.are.equals(401, redirStatus)
    end)
    it("will log an error message", function()
      assert.error_log_contains("but there's no session state found")
    end)
  end)
  describe("with bad state", function()
    local _, redirStatus = http.request({
          url = "http://localhost/default/redirect_uri?code=foo&state=X" .. state,
          headers = { cookie = cookie_header }
    })
    it("should be rejected", function()
       assert.are.equals(401, redirStatus)
    end)
    it("will log an error message", function()
      assert.error_log_contains("does not match state restored from session")
    end)
  end)
  describe("without state", function()
    local _, redirStatus = http.request({
          url = "http://localhost/default/redirect_uri?code=foo",
          headers = { cookie = cookie_header }
    })
    it("should be rejected", function()
       assert.are.equals(401, redirStatus)
    end)
    it("will log an error message", function()
      assert.error_log_contains("unhandled request to the redirect_uri")
    end)
  end)
  describe("without code", function()
    local _, redirStatus = http.request({
          url = "http://localhost/default/redirect_uri?state=" .. state,
          headers = { cookie = cookie_header }
    })
    it("should be rejected", function()
       assert.are.equals(401, redirStatus)
    end)
    it("will log an error message", function()
      assert.error_log_contains("unhandled request to the redirect_uri")
    end)
  end)
  describe("with all things set", function()
    local _, redirStatus, h = http.request({
          url = "http://localhost/default/redirect_uri?code=foo&state=" .. state,
          headers = { cookie = cookie_header },
          redirect = false
    })
    it("redirects to the original URI", function()
       assert.are.equals(302, redirStatus)
       assert.are.equals("/default/t", h.location)
    end)
  end)
end)
