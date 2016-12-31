require 'prometheus/client/rack/exporter'

module Squirrel
  def self.logger
    @logger ||= Logger.new STDOUT
  end

  module PrometheusClient
    class << self
      def counter(name)
        if valid_metric_name? name
          client.get(name.to_sym) || client.counter(name.to_sym, "Counter for #{name}")
        end
      end

      def summary(name)
        if valid_metric_name? name
          client.get(name.to_sym) || client.summary(name.to_sym, "Summary of #{name}")
        end
      end

      private

        def valid_metric_name?(name)
          !!(name.kind_of? String and name =~ /\A[a-z][_a-z]+[a-z]\Z/)
        end

        def client
          Prometheus::Client.registry
        end
    end
  end

  class Api < Sinatra::Base
    use Rack::CommonLogger
    use Rack::Deflater, if: ->(env, status, headers, body) { body.any? && body[0].length > 512 }
    use Prometheus::Client::Rack::Exporter

    helpers do 
      def labels
        if @request_payload
          @request_payload["labels"].map {|k,v| [k.to_sym, v] }.to_h || {}
        else
          {}
        end
      end
    end

    before do
      request.body.rewind
      @request_payload = Oj.load request.body.read
    end
    
    post "/counters/:name" do
      if counter = PrometheusClient.counter(params[:name])
        counter.increment labels, 1
        Squirrel.logger.info "Logged counter #{params[:name]}"
        "OK"
      else
        Squirrel.logger.warn "Invalid metric name #{params[:name]}"
        halt 404, "Invalid metric name given"
      end
    end

    post "/summaries/:name/:value" do
      if summary = PrometheusClient.summary(params[:name])
        summary.observe labels, params[:value].to_f
        Squirrel.logger.info "Logged summary #{params[:name]}"
        "OK"
      else
        Squirrel.logger.warn "Invalid metric name #{params[:name]}"
        halt 404, "Invalid metric name given"
      end
    end
  end
end