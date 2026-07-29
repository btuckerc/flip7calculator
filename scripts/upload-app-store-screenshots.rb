#!/usr/bin/env ruby

require "base64"
require "json"
require "net/http"
require "openssl"
require "optparse"
require "uri"

API_ROOT = "https://api.appstoreconnect.apple.com/v1"

options = {}
OptionParser.new do |parser|
  parser.on("--set ID") { |value| options[:set_id] = value }
  parser.on("--directory PATH") { |value| options[:directory] = value }
end.parse!

required_options = %i[set_id directory]
missing_options = required_options.reject { |key| options[key] }
abort "Missing options: #{missing_options.join(', ')}" unless missing_options.empty?

key_id = ENV.fetch("ASC_KEY_ID")
issuer_id = ENV.fetch("ASC_ISSUER_ID")
key_path = ENV.fetch("ASC_KEY_PATH")

def base64url(value)
  Base64.urlsafe_encode64(value, padding: false)
end

def token(key_id:, issuer_id:, key_path:)
  key = OpenSSL::PKey.read(File.read(key_path))
  now = Time.now.to_i
  header = base64url(JSON.generate(alg: "ES256", kid: key_id, typ: "JWT"))
  payload = base64url(JSON.generate(iss: issuer_id, iat: now, exp: now + 1_200, aud: "appstoreconnect-v1"))
  signing_input = "#{header}.#{payload}"
  der_signature = key.dsa_sign_asn1(OpenSSL::Digest::SHA256.digest(signing_input))
  signature_parts = OpenSSL::ASN1.decode(der_signature).value.map do |part|
    part.value.to_s(16).rjust(64, "0")
  end
  signature = [signature_parts.join].pack("H*")
  "#{signing_input}.#{base64url(signature)}"
end

AUTH_TOKEN = token(key_id: key_id, issuer_id: issuer_id, key_path: key_path)

def api_request(method, path, body: nil)
  uri = URI("#{API_ROOT}#{path}")
  request_class = {
    "DELETE" => Net::HTTP::Delete,
    "GET" => Net::HTTP::Get,
    "PATCH" => Net::HTTP::Patch,
    "POST" => Net::HTTP::Post
  }.fetch(method)
  request = request_class.new(uri)
  request["Authorization"] = "Bearer #{AUTH_TOKEN}"
  request["Content-Type"] = "application/json" if body
  request.body = JSON.generate(body) if body

  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    http.request(request)
  end
  return response if response.code.to_i.between?(200, 299)

  abort "App Store Connect #{method} #{path} failed (#{response.code}): #{response.body}"
end

def upload_part(operation, bytes)
  uri = URI(operation.fetch("url"))
  request_class = {
    "PUT" => Net::HTTP::Put,
    "POST" => Net::HTTP::Post
  }.fetch(operation.fetch("method"))
  request = request_class.new(uri)
  operation.fetch("requestHeaders", []).each do |header|
    request[header.fetch("name")] = header.fetch("value")
  end
  offset = operation.fetch("offset")
  length = operation.fetch("length")
  request.body = bytes.byteslice(offset, length)

  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    http.request(request)
  end
  return if response.code.to_i.between?(200, 299)

  abort "Screenshot part upload failed (#{response.code}): #{response.body}"
end

def wait_for_delivery(screenshot_id, timeout: 120)
  deadline = Time.now + timeout
  loop do
    response = api_request("GET", "/appScreenshots/#{screenshot_id}")
    data = JSON.parse(response.body).fetch("data")
    delivery = data.fetch("attributes").fetch("assetDeliveryState")
    state = delivery.fetch("state")
    return if state == "COMPLETE"
    abort "Screenshot delivery failed: #{delivery}" if state == "FAILED"
    abort "Timed out waiting for screenshot #{screenshot_id}" if Time.now >= deadline
    sleep 2
  end
end

set_id = options.fetch(:set_id)
directory = File.expand_path(options.fetch(:directory))
files = Dir.glob(File.join(directory, "*.png")).sort
abort "No PNG screenshots found in #{directory}" if files.empty?

existing_response = api_request("GET", "/appScreenshotSets/#{set_id}/appScreenshots?limit=50")
existing = JSON.parse(existing_response.body).fetch("data")
existing.each do |screenshot|
  api_request("DELETE", "/appScreenshots/#{screenshot.fetch('id')}")
end

files.each_with_index do |path, index|
  filename = File.basename(path)
  bytes = File.binread(path)
  create_payload = {
    data: {
      type: "appScreenshots",
      attributes: {
        fileName: filename,
        fileSize: bytes.bytesize
      },
      relationships: {
        appScreenshotSet: {
          data: { type: "appScreenshotSets", id: set_id }
        }
      }
    }
  }

  create_response = api_request("POST", "/appScreenshots", body: create_payload)
  screenshot = JSON.parse(create_response.body).fetch("data")
  screenshot.fetch("attributes").fetch("uploadOperations").each do |operation|
    upload_part(operation, bytes)
  end

  commit_payload = {
    data: {
      type: "appScreenshots",
      id: screenshot.fetch("id"),
      attributes: { uploaded: true }
    }
  }
  api_request("PATCH", "/appScreenshots/#{screenshot.fetch('id')}", body: commit_payload)
  wait_for_delivery(screenshot.fetch("id"))
  puts "Uploaded #{index + 1}/#{files.length}: #{filename}"
end
