Pod::Spec.new do |s|
  
  s.name                  = 'JSTP'
  s.version               = '0.1.4'
  s.summary               = 'JSTP is a data transfer protocol that uses JavaScript objects syntax as the encoding format and supports metadata'
  s.description           = 'JSTP'
  s.homepage              = 'https://github.com/metarhia/JSTP'
  s.license               = 'MIT'
  s.authors               = 'Gagnant', 'metarhia'
  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'
  s.source                = { :git => 'https://github.com/JSTPMobile/iOS.git', :tag => s.version.to_s }
  s.source_files          = 'JSTP/*.{h, swift, js}'
  s.dependency            = 'Socket'
  s.frameworks            = 'JavaScriptCore'
  
  s.subspec 'Socket' do |ss|
    ss.name   = 'Socket'
    ss.source = { :git => 'https://github.com/JSTPMobile/Socket-iOS.git', :tag => ss.version.to_s }
  end

end
