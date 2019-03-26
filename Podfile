# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

workspace 'FlickrGallery'

xcodeproj 'FlickrGallery.xcodeproj'
xcodeproj 'GalleryDomain/GalleryDomain.xcodeproj'
xcodeproj 'FlickerService/FlickerService.xcodeproj'

def flickr_gallery_pods
pod 'Swinject'
pod 'SwinjectStoryboard'
pod 'RxCocoa',    '~> 4.0'
end

def gallery_domain_pods
pod 'ReactorKit'
end

def common_pods
pod 'SwiftLint'
pod 'RxSwift',    '~> 4.0'
pod 'Then'
end

target 'FlickrGallery' do
xcodeproj 'FlickrGallery.xcodeproj'
flickr_gallery_pods
common_pods
end

target 'GalleryDomain' do
xcodeproj 'GalleryDomain/GalleryDomain.xcodeproj'
gallery_domain_pods
common_pods
end

target 'FlickerService' do
xcodeproj 'FlickerService/FlickerService.xcodeproj'
common_pods
end


