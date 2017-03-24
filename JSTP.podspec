Pod::Spec.new do |s|
  
  s.name        = 'JSTP'
  s.version     = '0.1.9.3'
  s.license     = { :type => "MIT" }

  s.homepage    = 'https://github.com/metarhia/JSTP'
  s.authors     = 'Gagnant', 'metarhia'

  s.summary     = 'JSTP is a data transfer protocol that uses JavaScript objects syntax as the encoding format and supports metadata'
  s.description = 'JSTP'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.6'

  s.source = {
    :git        => 'https://github.com/JSTPMobile/iOS.git', 
    :tag        => '#{s.version}',
    :submodules => true
  }

  s.resources = 'JSTP/*.{js}'

  s.source_files = 'JSTP/*.{swift}',
                   'Carthage/Checkouts/Socket/Socket/*.{swift}'

  s.frameworks = 'JavaScriptCore', 'Foundation'

end
