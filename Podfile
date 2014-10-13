
def import_pods
    pod 'CocoaLumberjack'
end

def import_pods_test

end

target "XLCUtils" do
    platform :osx, '10.9'
    import_pods
    
    target "XLCUtilsTests" do
        import_pods_test
    end
end


target "XLCUtils-ios" do
    platform :ios, '7.0'
    import_pods

    target "XLCUtils-iosTests" do
        import_pods_test
    end
end


