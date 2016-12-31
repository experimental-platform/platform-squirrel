require 'spec_helper'

describe Squirrel do
  describe Squirrel::Api do
    let(:app) { Squirrel::Api }
    include Rack::Test::Methods

    describe "POST /counters/:name" do
      it "increments the counter for valid metric names" do
        payload = { "labels" => { "method" => "GET", "path" => "/lol/wat" } }
        expect {
          post "/counters/my_metric", Oj.dump(payload)
        }.to change {
          Squirrel::PrometheusClient.counter("my_metric").values.length
        }.by(1)
        expect(last_response.status).to be == 200
        expect(last_response.body).to be == "OK"

        expect(Squirrel::PrometheusClient.counter("my_metric").values.keys).to be == [{method: 'GET', path: '/lol/wat'}]
      end

      it "responds with 404 for invalid names" do
        post "/counters/___"
        expect(last_response.status).to be == 404
        expect(last_response.body).to be == "Invalid metric name given"
      end
    end

    describe "POST /summaries/:name/:value" do
      it "increments the counter for valid metric names" do
        payload = { "labels" => { "method" => "GET", "path" => "/lol/wat" } }
        expect {
          post "/summaries/my_summary/0.123", Oj.dump(payload)
        }.to change {
          Squirrel::PrometheusClient.summary("my_summary").values.length
        }.by(1)
        expect(last_response.status).to be == 200
        expect(last_response.body).to be == "OK"

        expect(Squirrel::PrometheusClient.summary("my_summary").values.keys).to be == [{method: 'GET', path: '/lol/wat'}]
      end

      it "responds with 404 for invalid names" do
        post "/summaries/___/0.123"
        expect(last_response.status).to be == 404
        expect(last_response.body).to be == "Invalid metric name given"
      end
    end
  end
end