
ifeq ("$(ARCHS)","normal")
	ARCHS = armv6 armv7 i386
endif

HAXE_BUILDS := $(ARCHS:%=build-haxe-%)

ifeq ("$(ACTION)","clean")
default: clean
else
default: $(HAXE_BUILDS)
endif

ifeq ("$(CONFIGURATION)","Debug")
   BUILD_STYLE := Debug
endif

default: debug_print

ifeq ("$(BUILD_STYLE)","Debug")
   DEBUG := -debug
   DEF_DEBUG := -Ddebug
   CONFIG := Debug
   CONFIG_FILE := debug
else
   DEBUG :=
   DEF_DEBUG :=
   CONFIG := Release
   CONFIG_FILE := release
endif

ifeq ("$(CLANG_ENABLE_OBJC_ARC)", "YES")
   HXCPP_CLANG := -DHXCPP_CLANG -DOBJC_ARC
else
   HXCPP_CLANG := 
endif

HAXE_OS := $(PLATFORM_NAME)
ifeq ("$(HAXE_OS)","iphonesimulator")
   HAXE_OS := iphonesim
endif
CONFIG := $(CONFIG)-$(HAXE_OS)

debug_print:
	@echo "Make $(HAXE_BUILDS)"

LIB_BASE := build/$(CONFIG)/::MAIN::$(DEBUG)
LIB_DEST := $(DEBUG)/libHaxeApplication.a

export HXCPP_COMPILE_THREADS := 2

build-haxe-i386:
	@echo "Haxe simulator build CONFIG : $(CONFIG)"
	haxe Build_$(CONFIG_FILE)_simulator.hxml
	cd build/$(CONFIG); haxelib run hxcpp Build.xml -Dios -Diphone -Dsimulator -DHXCPP_CPP11 $(DEF_DEBUG) $(HXCPP_CLANG) ::foreach (PLATFORM.HXCPP_COMPILATION_ARGS)::::__current__:: ::end::
	cp $(LIB_BASE).iphonesim.a ../lib/i386$(LIB_DEST)
	touch ../Classes/Main.mm
	touch ../Classes/DUELLAppDelegate.m

build-haxe-armv6:
	@echo "Haxe armv6 build CONFIG : $(CONFIG)"
	haxe Build_$(CONFIG_FILE)_armv6.hxml
	cd build/$(CONFIG); haxelib run hxcpp Build.xml -Dios -Diphone -DHXCPP_ARMV6 -DHXCPP_CPP11 $(DEF_DEBUG) $(HXCPP_CLANG) ::foreach (PLATFORM.HXCPP_COMPILATION_ARGS)::::__current__:: ::end::
	cp $(LIB_BASE).iphoneos.a ../lib/armv6$(LIB_DEST)
	touch ../Classes/Main.mm
	touch ../Classes/DUELLAppDelegate.m

build-haxe-armv7:
	@echo "Haxe armv7 build CONFIG : $(CONFIG)"
	haxe Build_$(CONFIG_FILE)_armv7.hxml
	cd build/$(CONFIG); haxelib run hxcpp Build.xml -Dios -Diphone -DHXCPP_ARMV7 -DHXCPP_CPP11 $(DEF_DEBUG) $(HXCPP_CLANG) ::foreach (PLATFORM.HXCPP_COMPILATION_ARGS)::::__current__:: ::end::
	cp $(LIB_BASE).iphoneos-v7.a ../lib/armv7$(LIB_DEST)
	touch ../Classes/Main.mm
	touch ../Classes/DUELLAppDelegate.m

clean:
	rm -rf build
