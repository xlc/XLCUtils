Pod::Spec.new do |s|
  s.name         = "XLCUtils"
  s.version      = "0.0.1"
  s.summary      = "Some Objective-C Utilities"
  s.homepage     = "https://github.com/xlc/XLCUtils"
  s.license      = 'MIT'
  s.author       = { "Xiliang Chen" => "xlchen1291@gmail.com" }
  s.source       = { :git => "https://github.com/xlc/XLCUtils.git", :commit => "3e8fbc5a4389e8bde0c9d570c62597d870181c31" }
 
  s.source_files = 'XLCUtils/**/*.{h,hh,m,mm}'
  s.exclude_files = 'XLCUtils/NSObject+XLCUtilsMemoryDebug.{h,m}'
 
  s.ios.exclude_files = '**/osx/**'
  s.osx.exclude_files = '**/ios/**'
  s.private_header_files = '**/*Private.h'
  
  s.requires_arc = true
  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.8'
  
  s.subspec 'no-arc' do |sp|
    sp.source_files = 'XLCUtils/NSObject+XLCUtilsMemoryDebug.{h,m}'
    sp.requires_arc = false
  end

end
