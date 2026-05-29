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
      if target.name == 'Pods-VertixTests'
        config_file.other_linker_flags[:simple].delete_if { |f| f.include?('force_load') }
        config_file.other_linker_flags[:simple].delete_if { |f| f.include?('MediaPipe') }
      end
      xcconfig_path = target.xcconfig_path(config_name)
      config_file.save_as(xcconfig_path)
    end
  end
end