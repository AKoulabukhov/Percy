#
# Be sure to run `pod lib lint Percy.podspec' to ensure this is a
# valid spec before submitting.
#

Pod::Spec.new do |s|
  s.name             = 'Percy'
  s.version          = '0.1.0'
  s.swift_version    = '4.1'
  s.summary          = 'An elegant CoreData wrapper.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
                        Percy is abstraction over CoreData stack.
                        Just create CoreData model, structs mirroring this model
                        and conform them to Persistable protocol.
                        Now you have thread safe CRUD store to persist all of them.
                       DESC

  s.homepage         = 'https://github.com/akoulabukhov/Percy'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Alexander Kulabukhov' => 'wowid@list.ru' }
  s.source           = { :git => 'https://github.com/akoulabukhov/Percy.git', :tag => s.version.to_s }
  s.social_media_url = 'https://instagram.com/swift_codes'

  s.ios.deployment_target = '9.0'
  s.source_files = 'Percy/Classes/**/*'
  s.frameworks = 'CoreData'
  
end
