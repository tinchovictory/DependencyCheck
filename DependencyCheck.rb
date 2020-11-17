require_relative 'PodHelper'
require_relative 'XcodeHelper'

module DependencyCheck
  class Validator
    def initialize
      @ios_sdk = Xcode.ios_sdk
    end

    def project_dir
      # project_dir = '../fury_mobile-analytics-ios'
      project_dir = '../fury_andesui-ios'
    end

    def lib_files(extension)
      lib_sources = PodHelper.source_dirs(project_dir)
      files = []
      lib_sources.each do |source|
        files += Dir["#{project_dir}/#{source}/**/*.#{extension}"]
      end
      files
    end

    def lib_vendored_frameworks
      vendored_frameworks_paths = PodHelper.vendored_frameworks(project_dir)
      vendored_frameworks = []

      vendored_frameworks_paths.each do |path|
        framework = path.split(/\//).last
        framework = framework.split(/\./,2).first
        vendored_frameworks << framework
      end
      vendored_frameworks
    end

    def swift_imports(path)
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

    def swift_dependencies
      swift_files = lib_files('swift')
      dependencies = []
      swift_files.each do |file|
        dependencies += swift_imports(file)
      end
      dependencies.uniq
    end
    
    def objc_imports(path)
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

    def objc_dependencies
      obc_files = lib_files('h')
      obc_files += lib_files('m')
      dependencies = []
      obc_files.each do |file|
        dependencies += objc_imports(file)
      end
      dependencies.uniq
    end

    def dependencies
      dependencies = []
      dependencies += swift_dependencies
      dependencies += objc_dependencies
      dependencies
    end

    def sanitized_dependencies
      dependencies.reject do |dependency|
        @ios_sdk.include?(dependency) || lib_vendored_frameworks.include?(dependency)
      end
    end

    def execute
      puts sanitized_dependencies
    end
  end
end