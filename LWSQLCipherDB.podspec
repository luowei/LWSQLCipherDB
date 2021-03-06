#
# Be sure to run `pod lib lint LWSQLCipherDB.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'LWSQLCipherDB'
  s.version          = '1.0.0'
  s.summary          = '一个封装于FMDB 与 SQLCipher 的处理加密sqlite数据组件.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
LWSQLCipherDB，一个封装于FMDB 与 SQLCipher 的处理加密sqlite数据组件.
                       DESC

  s.homepage         = 'https://github.com/luowei/LWSQLCipherDB'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'luowei' => 'luowei@wodedata.com' }
  s.source           = { :git => 'https://github.com/luowei/LWSQLCipherDB.git'}
  # s.source           = { :git => 'https://gitlab.com/ioslibraries1/libsqlcipherdb.git' }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'LWSQLCipherDB/Classes/**/*'
  
  # s.resource_bundles = {
  #   'LWSQLCipherDB' => ['LWSQLCipherDB/Assets/*.png']
  # }

  # 参考：https://www.zetetic.net/sqlcipher/ios-tutorial/
  s.xcconfig = {
    'OTHER_CFLAGS' => '$(inherited) -DSQLITE_HAS_CODEC -DSQLITE_THREADSAFE -DSQLITE_TEMP_STORE=2 -DSQLCIPHER_CRYPTO_CC',
    'OTHER_LDFLAGS' => '$(inherited) -framework Security'
    # 'OTHER_CPPFLAGS' => '$(inherited) -I/usr/local/opt/openssl/include',
    # 'OTHER_LDFLAGS' => '$(inherited) -L/usr/local/opt/openssl/lib -framework Security'
  }


  s.public_header_files = 'LWSQLCipherDB/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'

  # s.dependency 'SQLCipher', '4.0'
  s.dependency 'SQLCipher'

end
