# frozen_string_literal: true

module BugsnagErrorEventDownloader
  class CLI < Thor
    class_option :token,
      aliases: ["-t"],
      banner: "BUGSNAG_PERSONAL_AUTH_TOKEN",
      type: :string,
      desc: "Path to the BUGSNAG_PERSONAL_AUTH_TOKEN with -t, "\
        "or set environment variable to BUGSNAG_PERSONAL_AUTH_TOKEN."

    desc("organizations", "Show organizations.")
    def organizations
      Output.puts Commands::Organizations.new.get
    rescue BugsnagErrorEventDownloader::NoAuthTokenError
      puts_error_no_auth_token_error
    rescue Bugsnag::Api::Unauthorized
      puts_error_bugsnag_api_unauthorized
    end

    desc("projects", "Show projects.")
    option :organization_id,
      aliases: ["-o"],
      required: true,
      type: :string,
      desc: "Path to the organization_id"
    def projects
      Output.puts Commands::Projects.new(
        organization_id: options[:organization_id]
      ).get
    rescue BugsnagErrorEventDownloader::NoAuthTokenError
      puts_error_no_auth_token_error
    rescue ValidationError => e
      puts_error_validation_error(e)
    rescue Bugsnag::Api::Unauthorized
      puts_error_bugsnag_api_unauthorized
    rescue Bugsnag::Api::NotFound
      puts_error_bugsnag_api_not_found
    end

    desc("generate_csv_map", "Generate csv map.")
    option :project_id,
      aliases: ["-p"],
      required: true,
      type: :string,
      desc: "Path to the project_id"
    option :error_id,
      aliases: ["-e"],
      required: true,
      type: :string,
      desc: "Path to the error_id"
    option :include_stacktrace,
      required: false,
      type: :boolean,
      desc: "Includes stacktrace(default: false, optional: true)",
      default: false
    option :include_breadcrumbs,
      required: false,
      type: :boolean,
      desc: "Includes breadcrumbs(default: false, optional: true)",
      default: false
    def generate_csv_map
      Output.puts Commands::GenerateCsvMap.new(
        project_id: options[:project_id],
        error_id: options[:error_id],
        include_stacktrace: options[:include_stacktrace],
        include_breadcrumbs: options[:include_breadcrumbs]
      ).generate
    rescue BugsnagErrorEventDownloader::NoAuthTokenError
      puts_error_no_auth_token_error
    rescue ValidationError => e
      puts_error_validation_error(e)
    rescue Bugsnag::Api::Unauthorized
      puts_error_bugsnag_api_unauthorized
    rescue Bugsnag::Api::NotFound
      puts_error_bugsnag_api_not_found
    end

    desc("error_events", "Show error events.")
    option :project_id,
      aliases: ["-p"],
      required: true,
      type: :string,
      desc: "Path to the project_id"
    option :error_id,
      aliases: ["-e"],
      required: true,
      type: :string,
      desc: "Path to the error_id"
    option :csv_map_path,
      aliases: ["-c"],
      required: true,
      type: :string,
      desc: "Path to the csv_map_path"
    def error_events
      Output.puts Commands::ErrorEvents.new(
        project_id: options[:project_id],
        error_id: options[:error_id],
        csv_map_path: options[:csv_map_path]
      ).get
    rescue BugsnagErrorEventDownloader::NoAuthTokenError
      puts_error_no_auth_token_error
    rescue ValidationError => e
      puts_error_validation_error(e)
    rescue Bugsnag::Api::Unauthorized
      puts_error_bugsnag_api_unauthorized
    rescue Bugsnag::Api::NotFound
      puts_error_bugsnag_api_not_found
    rescue Converter::CsvConverter::CsvMapNotFound
      Output.warn("csv_map not found.")
      Exit.run(status: 1)
    rescue Converter::CsvConverter::JSONInCsvMapIsInvalid
      Output.warn("JSON in csv_map is invalid.")
      Exit.run(status: 1)
    end

    no_commands do
      class << self
        def exit_on_failure?
          true
        end
      end
    end

    private

    def puts_error_no_auth_token_error
      message = "Set the environment variable BUGSNAG_PERSONAL_AUTH_TOKEN. "\
        "Or specify Bugsnag's token by specifying -t or -token."
      Output.warn(message)
      Exit.run(status: 1)
    end

    def puts_error_validation_error(error)
      Output.warn("You need specify '#{error.attributes.join(", ")}'. See -h or --help.")
      Exit.run(status: 1)
    end

    def puts_error_bugsnag_api_unauthorized
      Output.warn("Request denied because you do not have authorization.")
      Exit.run(status: 1)
    end

    def puts_error_bugsnag_api_not_found
      Output.warn("Resource not found in Bugsnag.")
      Exit.run(status: 1)
    end
  end
end
