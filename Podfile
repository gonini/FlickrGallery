# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'
use_frameworks!

workspace 'FlickrGallery'

project 'FlickrGallery.xcodeproj'
project 'GalleryDomain/GalleryDomain.xcodeproj'
project 'FlickerService/FlickerService.xcodeproj'

def flickr_gallery_pods
pod 'Swinject'
pod 'SwinjectStoryboard'
pod 'RxCocoa',    '~> 4.0'
end

def reactorKit_pods
pod 'ReactorKit'
end

def common_pods
pod 'SwiftLint'
pod 'RxSwift',    '~> 4.0'
end

target 'FlickrGallery' do
project 'FlickrGallery.xcodeproj'
flickr_gallery_pods
common_pods
reactorKit_pods
end

target 'GalleryDomain' do
project 'GalleryDomain/GalleryDomain.xcodeproj'
common_pods
reactorKit_pods
end

target 'FlickerService' do
project 'FlickerService/FlickerService.xcodeproj'
common_pods
end


