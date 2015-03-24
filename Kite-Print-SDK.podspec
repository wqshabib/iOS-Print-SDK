Pod::Spec.new do |spec|
  spec.name		= 'Kite-Print-SDK'
  spec.version         	= '2.0.13'
  spec.license 		= { :type => 'MIT', :file => 'Kite SDK/LICENSE' }
  spec.homepage         = 'https://github.com/OceanLabs/iOS-Print-SDK'
  spec.authors          = {'Deon Botha' => 'deon@oceanlabs.co'}
  spec.summary          = "Add physical print functionality in minutes! Print magnets, photo prints, postcards, polaroids, posters, stickers, canvas', phone cases, etc"
  spec.source           = {:git => 'https://github.com/OceanLabs/iOS-Print-SDK.git', :tag => '2.0.13'}
  spec.source_files     = ['Kite SDK/PSPrintSDK/OL*.{h,m}', 'Kite SDK/PSPrintSDK/CardIO*.h', 'Kite SDK/PSPrintSDK/RMImageCropper/*.{h,m}', 'Kite SDK/PSPrintSDK/Categories/*.{h,m}']
  spec.resources        = ['Kite SDK/PSPrintSDK/KitePrintSDK.xcassets', 'Kite SDK/*.lproj', 'Kite SDK/PSPrintSDK/OLKiteStoryboard.storyboard']
  spec.dependency	'SDWebImage'
  spec.dependency	'SVProgressHUD'
  spec.dependency	'AFNetworking', '2.5.0'
  spec.dependency	'UICKeyChainStore', '~> 2.0.4'
  spec.dependency	'LXReorderableCollectionViewFlowLayout'
  spec.dependency	'CTAssetsPickerController'
  spec.dependency 'FacebookImagePicker'
  spec.dependency 'InstagramImagePicker'
  spec.requires_arc	= true
  spec.platform		= :ios, '7.0'
  spec.social_media_url	= 'https://twitter.com/dbotha'
  spec.default_subspec = 'Lite'

  spec.subspec 'Lite' do |lite|
  #subspec for developers who don't want the third party PayPal, Stripe, Instagram, Facebook bloat
  end

  spec.subspec 'PayPal' do |paypal|
    paypal.xcconfig	=  { 'OTHER_CFLAGS' => '$(inherited) -DOL_KITE_OFFER_PAYPAL' }
    paypal.dependency	'PayPal-iOS-SDK', '~> 2.4.2'
  end

  spec.subspec 'ApplePay' do |apple|
    apple.xcconfig	  =  { 'OTHER_CFLAGS' => '$(inherited) -DOL_KITE_OFFER_APPLE_PAY' }
    apple.dependency	  'Stripe', '2.2.0'
    apple.dependency	  'Stripe/ApplePay'
  end

  spec.subspec 'Facebook' do |facebook|
    facebook.xcconfig =  { 'OTHER_CFLAGS' => '$(inherited) -DOL_KITE_OFFER_FACEBOOK' }
    facebook.dependency 'FacebookImagePicker'
  end

  spec.subspec 'Instagram' do |instagram|
    instagram.xcconfig =  { 'OTHER_CFLAGS' => '$(inherited) -DOL_KITE_OFFER_INSTAGRAM' }
    instagram.dependency 'InstagramImagePicker'
  end

end
