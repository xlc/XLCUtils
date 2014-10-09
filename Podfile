source 'https://github.com/CocoaPods/Specs.git'

def import_pods
    pod 'CocoaLumberjack'
end

def import_pods_test

end

target "XLCUtils" do
    platform :osx, '10.9'
    import_pods
    
    target "XLCUtilsTests", :exclusive => true do
        import_pods_test
    end
end


target "XLCUtils-ios" do
    platform :ios, '7.0'
    import_pods

    target "XLCUtils-iosTests", :exclusive => true do
        import_pods_test
    end
end


