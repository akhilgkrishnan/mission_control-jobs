module MissionControl::Jobs::ApplicationScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_application
    around_action :activate_job_server

    delegate :applications, to: MissionControl::Jobs
  end

  private
    def set_application
      @application = find_application or raise MissionControl::Jobs::Errors::ResourceNotFound, "Application not found"
      MissionControl::Jobs::Current.application = @application
    end

    def find_application
      if params[:application_id]
        applications[params[:application_id]]
      else
        applications.first
      end
    end

    def activate_job_server
      @original_redis = Resque.redis
      @server = find_server or raise MissionControl::Jobs::Errors::ResourceNotFound, "Server not found"
      MissionControl::Jobs::Current.server = @server
      yield
    ensure
      Resque.redis = @original_redis
    end

    def find_server
      if params[:server_id]
        MissionControl::Jobs::Current.application.servers[params[:server_id]]
      else
        @application.servers.first
      end
    end
end
