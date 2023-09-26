# frozen_string_literal: true

module BugsnagErrorEventDownloader
  module Commands
    class ErrorEvents
      def initialize(project_id:, error_id:, csv_map_path:, start_date:, end_date:)
        errors = []
        begin
          @client = BugsnagApiClient::ErrorEventClient.new(
            project_id: project_id,
            error_id: error_id,
            start_date: start_date,
            end_date: end_date
          )
        rescue ValidationError => e
          errors << e.attributes
        end
        begin
          @csv_converter = Converter::CsvConverter.new(csv_map_path: csv_map_path)
        rescue ValidationError => e
          errors << e.attributes
        end
        raise ValidationError.new(attributes: errors.flatten) unless errors.empty?
      end

      attr_reader :client, :csv_converter

      def get
        events = client.fetch_all
        csv_converter.convert(events)
      end
    end
  end
end
