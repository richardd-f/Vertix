platform :ios, '16.0'
use_frameworks! :linkage => :static
target 'Vertix' do
  pod 'Firebase/Auth'
  pod 'Firebase/Database'
  pod 'MediaPipeTasksVision'
  target 'VertixTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.aggregate_targets.each do |target|
    target.xcconfigs.each do |config_name, config_file|
      if target.name == 'Pods-Vertix'
        config_file.frameworks.delete('GTMSessionFetcher')
      end
      xcconfig_path = target.xcconfig_path(config_name)
      config_file.save_as(xcconfig_path)

      # The unit-test bundle is injected into the Vertix host app, which already
      # force-loads MediaPipe. Force-loading it again in the test target registers
      # MediaPipe's calculators twice and aborts the test runner on launch. These
      # flags live in OTHER_LDFLAGS[sdk=...] variants, which the CocoaPods API
      # doesn't expose cleanly, so strip them from the written file directly.
      if target.name == 'Pods-VertixTests'
        cleaned = File.readlines(xcconfig_path).reject do |line|
          line.include?('force_load') && line.include?('MediaPipe')
        end
        File.write(xcconfig_path, cleaned.join)
      end
    end
  end
end