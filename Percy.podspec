Pod::Spec.new do |s|
  
  s.name             = 'Percy'
  s.version          = '0.1.0'
  s.swift_version    = '5.0'
  s.summary          = 'An elegant CoreData wrapper.'
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
