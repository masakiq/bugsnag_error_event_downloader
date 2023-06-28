# frozen_string_literal: true

module BugsnagErrorEventDownloader
  module Converter
    class CsvConverter
      class CsvMapNotFound < StandardError; end
      class JSONInCsvMapIsInvalid < StandardError; end

      def initialize(csv_map_path:)
        errors = []
        errors << "csv_map_path" unless csv_map_path
        raise ValidationError.new(attributes: errors) unless errors.empty?

        @csv_map = parse_csv_map(csv_map_path)
      end

      attr_reader :csv_map

      def convert(events)
        CSV.generate do |rows|
          headers = csv_map.map { |m| m["header"] }
          rows << headers
          events.each do |event|
            json = deep_hash(event).to_json
            paths = csv_map.map { |m| m["path"] }
            row = paths.map do |path|
              json_path = JsonPath.new(path)
              begin
                json_path.on(json).uniq.join(",")
              rescue ArgumentError
                ""
              end
            end
            rows << row
          end
        end
      end

      private

      def deep_hash(object)
        case object
        when Hash
          object.each_with_object({}) do |(key, value), hash|
            hash[key] = deep_hash(value)
          end
        when Array
          object.map { |value| deep_hash(value) }
        when Sawyer::Resource
          deep_hash(object.to_h)
        else
          object
        end
      end

      def parse_csv_map(path)
        csv_map_file = File.read(path)
        JSON.parse(csv_map_file)
      rescue Errno::ENOENT
        raise CsvMapNotFound
      rescue JSON::ParserError
        raise JSONInCsvMapIsInvalid
      end
    end
  end
end
