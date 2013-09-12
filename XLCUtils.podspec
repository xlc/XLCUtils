Pod::Spec.new do |s|
  s.name         = "XLCUtils"
  s.version      = "0.0.1"
  s.summary      = "Some Objective-C Utilities"
  s.homepage     = "https://github.com/xlc/XLCUtils"
  s.license      = 'MIT'
  s.author       = { "Xiliang Chen" => "xlchen1291@gmail.com" }
  s.source       = { :git => "https://github.com/xlc/XLCUtils.git", :commit => "fb9216ee32adc9e668dc9d06dbda3cf05416f596" }
  s.source_files = 'XLCUtils'
  s.exclude_files = 'XLCUtils/NSObject+XLCUtilsMemoryDebug.m'
  s.requires_arc = true

  s.ios.deployment_target = '6.0'

  s.osx.deployment_target = '10.8'
  
  s.subspec 'no-arc' do |sp|
    sp.source_files = 'XLCUtils/NSObject+XLCUtilsMemoryDebug.m'
    sp.requires_arc = false
  end

end
