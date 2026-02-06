# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'DramaBox' do
  # Comment the next line if you don't want to use dynamic frameworks

  pod 'Alamofire'
  pod "SwiftyJSON"
  pod 'SVProgressHUD'
  pod 'SwiftyStoreKit'
  pod 'Firebase/Analytics'
  pod 'Firebase/RemoteConfig'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Performance'
  pod 'Google-Mobile-Ads-SDK'
  pod 'MBProgressHUD'
  pod 'AWSMobileClient', '~> 2.6.13'
  pod 'AWSS3'
  pod "SkeletonView"
  pod 'NVActivityIndicatorView'
  pod 'Cosmos', '~> 25.0'
  pod 'iOSDropDown'
  pod 'IQKeyboardManagerSwift'
  pod 'lottie-ios'
  pod 'SDWebImage', '~> 5.0'
  pod 'SVProgressHUD'
  pod 'ReachabilitySwift'
  pod 'SwiftPopup'
  pod 'MarqueeLabel'
  pod 'SwiftFortuneWheel'
  use_frameworks!

  # Pods for DramaBox

end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      end
    end
  end
end
