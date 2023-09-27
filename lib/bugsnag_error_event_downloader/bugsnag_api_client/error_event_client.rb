# frozen_string_literal: true

require "forwardable"

module BugsnagErrorEventDownloader
  module BugsnagApiClient
    class ErrorEventClient
      def initialize(
        project_id:,
        error_id:,
        start_date: nil,
        end_date: Time.now.to_i
      )
        @client = Client.new

        errors = []
        errors << "project_id" unless project_id
        errors << "error_id" unless error_id
        raise ValidationError.new(attributes: errors) unless errors.empty?

        @project_id = project_id
        @error_id = error_id
        @start_date = start_date ? Time.at(start_date).utc : Time.at(end_date).utc - (60 * 60 * 24 * 1)
        @end_date = Time.at(end_date).utc
      end

      attr_reader :client, :project_id, :error_id, :start_date, :end_date

      def fetch_first
        events = []
        error_events = fetch(base_time: end_date)
        error_events.each do |error_event|
          return events if error_event.received_at < start_date

          events << error_event
        end
        events.uniq!(&:id)
        events
      end

      def fetch_all
        events = fetch_first
        events.concat(fetch_subsequent)
      end

      private

      def fetch(base_time:)
        client.error_events(
          project_id,
          error_id,
          base: base_time.strftime("%Y-%m-%dT%H:%M:%SZ"),
          full_reports: true
        )
      end

      def fetch_subsequent
        events = []
        until client.last_response.rels[:next].nil?
          begin
            base_time = client.last_response.data.last.received_at
            error_events = fetch(base_time: base_time)
            error_events.each do |error_event|
              return events if error_event.received_at < start_date

              events << error_event
            end
            events.uniq!(&:id)
            puts "Currently #{events.size} events downloaded, in progress..."
          rescue Bugsnag::Api::RateLimitExceeded => e
            # Bugsnag API document --- Rate Limiting
            # https://bugsnagapiv2.docs.apiary.io/#introduction/rate-limiting
            retry_after = e.instance_variable_get(:@response).response_headers["retry-after"].to_i
            puts "RateLimitExceeded Retry-After: #{retry_after} seconds"
            sleep(retry_after)
          end
        end
        events
      end
    end
  end
end
