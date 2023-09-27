# frozen_string_literal: true

RSpec.describe(BugsnagErrorEventDownloader::BugsnagApiClient::ErrorEventClient) do
  before do
    allow(BugsnagErrorEventDownloader::BugsnagApiClient::Client).to(receive(:new).and_return(bugsnag_api_client))
  end

  let(:instance) { described_class.new(project_id: project_id, error_id: error_id) }
  let(:bugsnag_api_client) { instance_double(BugsnagErrorEventDownloader::BugsnagApiClient::Client) }
  let(:option) { instance_double(BugsnagErrorEventDownloader::Option) }

  describe(".initialize") do
    context "when project_id and error_id are exists" do
      let(:project_id) { "project_id" }
      let(:error_id) { "error_id" }

      it { expect(instance).to(be_a(described_class)) }
    end

    context "when project_id is not exists" do
      let(:project_id) { nil }
      let(:error_id) { "error_id" }

      it do
        expect { instance }.to(raise_error(BugsnagErrorEventDownloader::ValidationError) do |error|
          expect(error.attributes).to(eq(["project_id"]))
        end)
      end
    end

    context "when error_id is not exists" do
      let(:project_id) { "project_id" }
      let(:error_id) { nil }

      it do
        expect { instance }.to(raise_error(BugsnagErrorEventDownloader::ValidationError) do |error|
          expect(error.attributes).to(eq(["error_id"]))
        end)
      end
    end
  end

  describe("#fetch_first") do
    subject(:fetch_first) { instance.fetch_first }

    let(:project_id) { "project_id" }
    let(:error_id) { "error_id" }

    let(:error_event) do
      agent = Sawyer::Agent.new("https://api.bugsnag.com")
      data = {
        id: "33333",
        url: "https://api.bugsnag.com/projects/11111/events/33333",
        project_url: "https://api.bugsnag.com/projects/11111",
        is_full_report: true,
        error_id: "22222",
        received_at: Time.now.utc - (60 * 60 * 1),
        exception: [
          {
            error_class: "NotFoundError",
            message: "Response code = 404",
          },
        ],
      }
      Sawyer::Resource.new(agent, data)
    end

    before do
      allow(bugsnag_api_client).to(receive(:error_events).and_return([error_event]))
    end

    it { expect(fetch_first).to(eq([error_event])) }

    it do
      fetch_first
      expect(bugsnag_api_client)
        .to(have_received(:error_events)
        .with(
          "project_id",
          "error_id",
          base: /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/,
          full_reports: true,
        ))
    end
  end

  describe "#fetch_all" do
    subject(:fetch_all) { instance.fetch_all }

    let(:project_id) { "project_id" }
    let(:error_id) { "error_id" }

    let(:error_event_1) do
      agent = Sawyer::Agent.new("https://api.bugsnag.com")
      data = {
        id: "11111",
        url: "https://api.bugsnag.com/projects/11111/events/11111",
        project_url: "https://api.bugsnag.com/projects/11111",
        is_full_report: true,
        error_id: "11111",
        received_at: Time.now.utc - (60 * 60 * 1),
        exception: [
          {
            error_class: "NotFoundError",
            message: "Response code = 404",
          },
        ],
      }
      Sawyer::Resource.new(agent, data)
    end

    let(:error_event_2) do
      agent = Sawyer::Agent.new("https://api.bugsnag.com")
      data = {
        id: "22222",
        url: "https://api.bugsnag.com/projects/11111/events/22222",
        project_url: "https://api.bugsnag.com/projects/11111",
        is_full_report: true,
        error_id: "11111",
        received_at: Time.now.utc - (60 * 60 * 2),
        exception: [
          {
            error_class: "NotFoundError",
            message: "Response code = 404",
          },
        ],
      }
      Sawyer::Resource.new(agent, data)
    end

    before do
      allow(bugsnag_api_client).to(receive(:error_events).and_return([error_event_1], [error_event_2]))
      rel = Sawyer::Relation.from_link(nil, :next, { href: "/users/1", method: :get })
      last_response_has_rels = instance_double(Sawyer::Response, rels: { next: rel })
      last_response_has_data = instance_double(Sawyer::Response, data: [error_event_1])
      last_response_no_rels = instance_double(Sawyer::Response, rels: { next: nil })
      allow(bugsnag_api_client)
        .to(receive(:last_response)
        .and_return(
          last_response_has_rels,
          last_response_has_data,
          last_response_no_rels
        ))
    end

    it do
      expect(fetch_all).to(eq([error_event_1, error_event_2]))
    end
  end
end
