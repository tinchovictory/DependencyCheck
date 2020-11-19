require_relative 'helpers/PodHelper'
require_relative 'helpers/XcodeHelper'

module DependencyCheck
  class Validator
    def initialize
      @ios_sdk = Xcode.ios_sdk
      @ios_sdk.map!(&:downcase)
    end

    def project_dir
      # project_dir = '../fury_mobile-analytics-ios'
      project_dir = './projects/fury_ui-components-ios'
    end

    def lib_files spec
      lib_sources = PodHelper.spec_sources(spec)
      files = []
      lib_sources.each do |source|
        # Add the project dir at the start of the source
        source.prepend("#{project_dir}/")

        # If the source is a directory check files recursively
        source += "/**/*" if File.directory?(source)

        files += Dir.glob(source)
      end
      files
    end

    def files_with_extension files, extension
      files.select do |file|
        file =~ /^.*\.#{extension}$/
      end
    end

    def lib_vendored_frameworks spec
      vendored_frameworks_paths = PodHelper.vendored_frameworks(spec)
      vendored_frameworks = []

      vendored_frameworks_paths.each do |path|
        # Keep the last part of the path after /
        framework = path.split(/\//).last
        # Remove the .framework extension
        framework = framework.split(/\./,2).first

        vendored_frameworks << framework
      end
      vendored_frameworks
    end

    def swift_imports path
      imports = []
      File.open(path, 'r') do |f|
        import_lines = f.select do |line|
          line =~ /import/
        end

        import_lines.each do |import|
          import.slice! 'import'
          imports << import.strip
        end
      end
      imports.uniq
    end

    def swift_dependencies spec_files
      swift_files = files_with_extension(spec_files, 'swift')
      dependencies = []
      swift_files.each do |file|
        dependencies += swift_imports(file)
      end
      dependencies.uniq
    end
    
    def objc_imports path
      imports = []
      File.open(path, 'r') do |f|
        import_lines = f.select do |line|
          line =~ /#import[ ]+</
        end

        import_lines.each do |import|
          import.slice! '#import'
          import.strip!
          import.slice! '<'
          imports << import.split(/\//, 2).first
        end
      end
      imports.uniq
    end

    def objc_dependencies spec_files
      objc_files = files_with_extension(spec_files, 'h')
      objc_files += files_with_extension(spec_files, 'm')
      dependencies = []
      objc_files.each do |file|
        dependencies += objc_imports(file)
      end
      dependencies.uniq
    end

    def dependencies spec
      spec_files = lib_files(spec)
      dependencies = []
      dependencies += swift_dependencies(spec_files)
      dependencies += objc_dependencies(spec_files)
      dependencies
    end

    def sanitized_dependencies spec
      dependencies(spec).reject do |dependency|
        @ios_sdk.include?(dependency.downcase)
      end.uniq
    end

    def check_spec_dependencies spec, pod_name
      code_dependencies = sanitized_dependencies(spec)
      missing_dependencies = []

      # Remove dependencies to default spec
      missing_dependencies = code_dependencies.reject do |dependency|
        dependency == pod_name
      end

      # Remove vendored frameworks
      missing_dependencies = missing_dependencies.reject do |dependency|
        lib_vendored_frameworks(spec).include?(dependency)
      end

      # Remove dependencies defined in the spec
      defined_spec_dependencies = PodHelper.spec_dependencies(spec)
      missing_dependencies = missing_dependencies.reject do |dependency|
        defined_spec_dependencies.include?(dependency)
      end

      missing_dependencies
    end

    def check_project_dependencies path
      pod_name = PodHelper.pod_name(path)
      missing_dependencies_by_spec = {}

      PodHelper.specs(path).each do |spec|
        missing_dependencies = check_spec_dependencies(spec, pod_name)

        unless missing_dependencies.empty?
          spec_name = PodHelper.spec_name(spec)
          missing_dependencies_by_spec[spec_name] = missing_dependencies
        end
      end

      missing_dependencies_by_spec
    end

    def log_missing_dependencies dependencies, path
      pod_name = PodHelper.pod_name(path)

      dependencies.each do |key, value|
        spec_type = "default spec"
        unless key == pod_name
          spec_type = "subspec"
          key = "#{pod_name}/#{key}"
        end

        puts "Missing dependendencies on #{spec_type} #{key}:"
        puts value
        puts "\n"
      end
    end

    def execute
      missing_dependencies = check_project_dependencies(project_dir)
      log_missing_dependencies(missing_dependencies, project_dir)
    end
  end
end