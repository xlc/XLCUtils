Pod::Spec.new do |s|
  s.name         = "XLCUtils"
  s.version      = "0.0.1"
  s.summary      = "Some Objective-C Utilities"
  s.description  = <<-DESC
                  Some Objective-C Utilities.
                  DESC
  s.homepage     = "https://github.com/xlc/XLCUtils"
  s.license      = 'MIT'
  s.author       = { "Xiliang Chen" => "xlchen1291@gmail.com" }
  s.source       = { :git => "https://github.com/xlc/XLCUtils.git", :commit => "fb9216ee32adc9e668dc9d06dbda3cf05416f596" }
  s.source_files  = 'XLCUtils', 'XLCUtils/**/*.{h,m,mm}'
  s.requires_arc = true
end
