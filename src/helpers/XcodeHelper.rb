module DependencyCheck
  class Xcode
    def self.xcode_path
      "/Applications/Xcode12.app/Contents"
    end

    def self.private_frameworks_path
      "#{xcode_path}/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/Frameworks"
    end

    def self.extract_name framework
      # Keep the last part of the path after /
      framework = framework.split(/\//).last

      # Remove the .framework extension
      framework.split(/\./,2).first
    end

    def self.ios_sdk
      frameworks = Dir["#{private_frameworks_path}/*.{framework}"]

      frameworks = frameworks.collect do |framework|
        extract_name(framework)
      end

      frameworks
    end
  end
end