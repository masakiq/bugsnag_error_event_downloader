# frozen_string_literal: true

module BugsnagErrorEventDownloader
  module Commands
    class GenerateCsvMap
      include Thor::Base

      def initialize(project_id:, error_id:, include_stacktrace:, include_breadcrumbs:)
        @client = BugsnagApiClient::ErrorEventClient.new(
          project_id: project_id,
          error_id: error_id,
          start_date: Time.now.to_i - 60 * 60 * 24 * 30,
        )
        @include_stacktrace = include_stacktrace
        @include_breadcrumbs = include_breadcrumbs
      end

      attr_reader :client, :include_stacktrace, :include_breadcrumbs

      def generate
        events = client.fetch_first
        json_paths = extract_json_paths(events)
        json_paths = reject_stacktrace(json_paths) unless include_stacktrace
        json_paths = reject_breadcrumbs(json_paths) unless include_breadcrumbs
        csv_map = generate_csv_map(json_paths)
        csv_map.to_json
      end

      private

      def extract_json_paths(events)
        json_paths = []
        events.each do |event|
          json = JSON.parse(event.to_h.to_json)
          json_path = ::JsonPath.fetch_all_path(json)
          json_paths.concat(json_path)
        end
        json_paths.uniq
      end

      def reject_stacktrace(json_paths)
        json_paths.reject do |json_path|
          json_path.include?("stacktrace")
        end
      end

      def reject_breadcrumbs(json_paths)
        json_paths.reject do |json_path|
          json_path.include?("breadcrumbs")
        end
      end

      def generate_csv_map(json_paths)
        json_paths[1..].map { |path| { header: path, path: path } }
      end
    end
  end
end
