/*
 *  Main.mm
 *
 *  Boot code for duell.
 *
 */

#include <stdio.h>

#import <UIKit/UIKit.h>

#import "DUELLAppDelegate.h"


extern "C" void hxcpp_set_top_of_stack();
	
::foreach NDLLS::
 ::if (REGISTER_STATICS)::
     extern "C" int ::NAME::_register_prims();
 ::end::
::end::

extern "C" int main(int argc, char *argv[])	
{
	hxcpp_set_top_of_stack();

   	::foreach NDLLS::
     ::if (REGISTER_STATICS)::
      ::NAME::_register_prims();
     ::end::
   	::end::

    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([DUELLAppDelegate class]));
    }

	return 0;
}
