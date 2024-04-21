module Fastlane
  module Actions
    class GradleUpdateAction < Action
      def self.run(params)
        gradle_sh, gradle_path = determine_gradle(params)
      end

      def self.determine_gradle(params)
        # on linux
        if FastlaneCore::Helper.linux?
          gradle_version = params[:gradle_version]
          gradle_path = File.expand_path(params[:gradle_version], params[:gradle_dir])
          gradle_sh = File.expand_path("bin/gradle", gradle_path)
          if File.exist?(gradle_sh)
            UI.message("Using existing gradle at #{gradle_path}")
          else
            UI.message("Downloading gradle to #{gradle_path}")
            download_url = "https://services.gradle.org/distributions/gradle-#{gradle_version}-bin.zip"
            download_and_extract_gradle(download_url, gradle_version, gradle_path)
          end

        else
          UI.user_error! 'Your OS is currently not supported.'
        end

        ENV['GRADLE_HOME'] = gradle_path
        [gradle_sh, gradle_path]
      end

      def self.download_and_extract_gradle(download_url, gradle_version, target_path)
        FastlaneCore::CommandExecutor.execute(command: "wget -O /tmp/gradle-#{gradle_version}.zip #{download_url}",
                                              print_all: true,
                                              print_command: true)
        FastlaneCore::CommandExecutor.execute(command: "mkdir -p #{target_path}",
                                              print_all: true,
                                              print_command: true)
        FastlaneCore::CommandExecutor.execute(command: "unzip -qo /tmp/gradle-#{gradle_version}.zip -d #{target_path}",
                                              print_all: true,
                                              print_command: true)
      ensure
        FastlaneCore::CommandExecutor.execute(command: "rm -f /tmp/gradle-#{gradle_version}.zip",
                                              print_all: true,
                                              print_command: true)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Install and update Gradle"
      end

      def self.details
        [
          "The initial Gradle will be downloaded as zip archive.",
        ].join("\n")
      end

      def self.example_code
        [
          'gradle_update(
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
                                        env_name: "FL_GRADLE_DIR",
                                        description: "Directory for Gradle",
                                        optional: true,
                                        default_value: "~/.gradle-fastlane"),
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
