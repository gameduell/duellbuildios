## Description

Use this plugin to build for the ios platform.

## Usage:
`$ duell build ios -simulator -debug`
## Arguments:
* `-simulator` &ndash; runs the app on the ios simulator.
* `-debug` &ndash; Use this argument if you want to build in debug.

## Release Log

# v3.5
* added main view to app delegate so that libraries can retrieve/set the main view to make integration easier.

# v5.0
* added support for Xcode 8.

# v6.0.5
* added correct template for default launch images
* image name    orientation     point resolution
* ~ipad
* Default-Landscape Landscape {768, 1024}
* Default-Portrait Portrait {768, 1024}
* Default-736h Portrait {414, 736}
* ~iphone
* Default Portrait {320, 480}
* Default-568h Portrait {320, 568}
* Default-667h Portrait {375, 667}
* Default-736h Portrait {414, 736}
* Default-812h Portrait {375, 812}

# v.7.0.2
* Ios 11 sdk compatibility for Icons asset catalog
* Icons folder required to contain an asset catalog name Images.xcassets containing AppIcon.appiconset

## Next Major TODOs

* Properly name required-capability, capability, fullscreen and requires-fullscreen to something less confusing.