module Fastlane
  module Actions
    module SharedValues
      GRADLE_HOME = :GRADLE_HOME
      GRADLE_BIN = :GRADLE_BIN
    end

    class GradleUpdateAction < Action
      def self.run(params)
        gradle_sh, gradle_path = determine_gradle(params)

        Actions.lane_context[SharedValues::GRADLE_HOME] = gradle_path
        Actions.lane_context[SharedValues::GRADLE_BIN] = gradle_sh

        return gradle_path
      end

      def self.get_download_tool(params)
        case FastlaneCore::Helper.operating_system
        when "macOS"
          return params[:download_tool_macos]
        when "linux"
          return params[:download_tool_linux]
        else
          UI.user_error!("Operating system not supported: #{FastlaneCore::Helper.operating_system}")
        end
      end

      def self.get_download_command(download_tool, download_url, output_path)
        case download_tool
        when "wget"
          return "wget -O #{output_path} #{download_url}"
        when "curl"
          return "curl -L #{download_url} -o #{output_path}"
        end
      end

      def self.determine_gradle(params)
        # on linux
        if FastlaneCore::Helper.linux? || FastlaneCore::Helper.mac?
          gradle_version = params[:gradle_version]
          gradle_install_path = File.expand_path(params[:gradle_dir])
          gradle_path = File.expand_path("gradle-#{gradle_version}", gradle_install_path)
          gradle_sh = File.expand_path("bin/gradle", gradle_path)

          if File.exist?(gradle_sh)
            UI.message("Using existing gradle at #{gradle_path}")
          else
            UI.message("Downloading gradle to #{gradle_install_path}")
            download_url = "https://services.gradle.org/distributions/gradle-#{gradle_version}-bin.zip"
            download_and_extract_gradle(params, download_url, gradle_version, gradle_install_path)
          end

        else
          UI.user_error! 'Your OS is currently not supported.'
        end

        [gradle_sh, gradle_path]
      end

      def self.download_and_extract_gradle(params, download_url, gradle_version, target_path)
        download_path = "/tmp/gradle-#{gradle_version}.zip"
        download_tool = get_download_tool(params)
        download_cmd = get_download_command(download_tool, download_url, download_path)

        FastlaneCore::CommandExecutor.execute(command: download_cmd,
                                              print_all: true,
                                              print_command: true)
        FastlaneCore::CommandExecutor.execute(command: "mkdir -p #{target_path}",
                                              print_all: true,
                                              print_command: true)
        FastlaneCore::CommandExecutor.execute(command: "unzip -qo #{download_path} -d #{target_path}",
                                              print_all: true,
                                              print_command: true)
      ensure
        FastlaneCore::CommandExecutor.execute(command: "rm -f #{download_path}",
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
          FastlaneCore::ConfigItem.new(key: :download_tool_linux,
                                        env_name: "FL_DOWNLOAD_TOOL_LINUX",
                                        description: "Tool to download files in linux",
                                        optional: true,
                                        default_value: "wget"),
          FastlaneCore::ConfigItem.new(key: :download_tool_macos,
                                        env_name: "FL_DOWNLOAD_TOOL_MACOS",
                                        description: "Tool to download files in macOS",
                                        optional: true,
                                        default_value: "curl"),
        ]
      end

      def self.output
        [
          ["GRADLE_HOME", "The install location of gradle"],
          ["GRADLE_BIN", "The location of the gradle executable"]
        ]
      end

      def self.return_value
        "The install location of gradle"
      end

      def self.return_type
        :string
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
