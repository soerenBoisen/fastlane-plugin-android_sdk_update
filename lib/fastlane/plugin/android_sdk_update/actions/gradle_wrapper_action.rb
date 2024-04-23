module Fastlane
  module Actions
    class GradleWrapperAction < Action
      def self.run(params)
        android_project_dir = params[:android_project_dir]
        gradle_version = params[:gradle_version]
        validate_url = params[:validate_url]

        gradle_sh, gradle_path = determine_gradle(params)

        call_gradle_wrapper(android_project_dir, gradle_sh, gradle_version, validate_url)
      end

      def self.determine_gradle(params)
        # on linux
        if FastlaneCore::Helper.linux?
          gradle_dir = params[:gradle_dir]
          gradle_path = File.expand_path(gradle_dir)
          gradle_sh = File.expand_path("bin/gradle", gradle_path)
          if File.exist?(gradle_sh)
            UI.message("Using existing gradle at #{gradle_path}")
          else
            UI.user_error! 'No gradle installation found.'
          end

        else
          UI.user_error! 'Your OS is currently not supported.'
        end

        [gradle_sh, gradle_path]
      end

      def self.call_gradle_wrapper(android_project_dir, gradle_sh, gradle_version, validate_url)
        validate_url_param = validate_url ? " --validate-url" : ""
        Dir.chdir(android_project_dir) do
          FastlaneCore::CommandExecutor.execute(command: "#{gradle_sh} wrapper --gradle-version #{gradle_version}#{validate_url_param}",
                                                print_all: true,
                                                print_command: true)
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Install the gradle wrapper"
      end

      def self.details
        [
          "Uses the gradle in GRADLE_HOME.",
        ].join("\n")
      end

      def self.example_code
        [
          'gradle_wrapper(
            gradle_version: "7.6"
          )'
        ]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :gradle_version,
                                       env_name: "FL_GRADLE_VERSION",
                                       description: "Gradle version to be installed",
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :gradle_dir,
                                       env_name: "FL_GRADLE_DIRECTORY",
                                       description: "Folder where Gradle is installed",
                                       optional: true,
                                       default_value: Actions.lane_context[SharedValues::GRADLE_HOME] || ENV["GRADLE_HOME"]),
          FastlaneCore::ConfigItem.new(key: :android_project_dir,
                                       env_name: "FL_GRADLE_ANDROID_PROJECT_DIR",
                                       description: "Subfolder where the android project resides",
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :validate_url,
                                       env_name: "FL_GRADLE_VALIDATE_URL",
                                       description: "Update all installed packages to the latest versions",
                                       is_string: false,
                                       default_value: false),
        ]
      end

      def self.authors
        ["Søren Boisen"]
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
