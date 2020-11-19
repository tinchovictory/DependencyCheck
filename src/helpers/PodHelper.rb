require 'cocoapods'

module DependencyCheck
  class PodHelper
    def self.podspec_path(project_dir)
      Dir["#{project_dir}/**/*.podspec"].first
    end

    def self.podspec(path)
      Pod::Specification.from_file(podspec_path(path))
    end

    def self.pod_name path
      spec_name(podspec(path))
    end

    def self.spec_name spec
      spec.attributes_hash['name']
    end

    def self.specs(path)
      specs = []
      specs << podspec(path)
      specs += podspec(path).subspecs
      specs
    end

    def self.spec_sources(spec)
      paths = []
      unless spec.attributes_hash['source_files'].nil?
        [spec.attributes_hash['source_files']].flatten.each do |dir|
          paths.append(dir.split('/**')[0])
        end
      end
      paths
    end

    def self.spec_dependencies(spec)
      dependencies = []
      unless spec.attributes_hash['dependencies'].nil?
        dependencies += spec.attributes_hash['dependencies'].keys
      end
      dependencies
    end

    # def self.paths(spec)
    #   paths = []
    #   unless spec.attributes_hash['source_files'].nil?
    #     [spec.attributes_hash['source_files']].flatten.each do |dir|
    #       paths.append(dir.split('/**')[0])
    #     end
    #   end
    #   paths
    # end
  
    # def self.source_dirs(path)
    #   paths = paths(podspec(path))
    #   podspec(path).subspecs.each do |subspec|
    #     paths.append(paths(subspec))
    #   end
    #   paths.flatten
    # end

    def self.vendored_frameworks(spec)
      frameworks = []
      unless spec.attributes_hash['vendored_frameworks'].nil?
        [spec.attributes_hash['vendored_frameworks']].flatten.each do |dir|
          frameworks.append(dir.split('/**')[0])
        end
      end
      frameworks
    end

    # def self.vendored_frameworks(path)
    #   frameworks = frameworks(podspec(path))
    #   podspec(path).subspecs.each do |subspec|
    #     frameworks.append(frameworks(subspec))
    #   end
    #   frameworks.flatten
    # end
  end
end
