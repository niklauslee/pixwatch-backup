# This file is part of Espruino, a JavaScript interpreter for Microcontrollers
#
# Copyright (C) 2013 Gordon Williams <gw@pur3.co.uk>
# Copyright (C) 2014 Alain Sézille for NucleoF401RE, NucleoF411RE specific lines of this file
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# -----------------------------------------------------------------------------
# Makefile for Espruino
# -----------------------------------------------------------------------------
# Set ONE of the following environment variables to compile for that board:
#
# ESPRUINO_1V0=1          # Espruino board rev 1.0
# ESPRUINO_1V1=1          # Espruino board rev 1.1 and 1.2
# ESPRUINO_1V3=1          # Espruino board rev 1.3 and rev 1v4
# PICO_1V0=1              # Espruino Pico board rev 1.0
# PICO_1V1=1              # Espruino Pico board rev 1.1
# PICO_1V2=1              # Espruino Pico board rev 1.2
# PICO_1V3=1              # Espruino Pico board rev 1.3
# OLIMEXINO_STM32=1       # Olimexino STM32
# MAPLERET6_STM32=1       # Limited production Leaflabs Maple r5 with a STM32F103RET6
# MAPLEMINI=1             # Leaflabs Maple Mini
# EMBEDDED_PI=1           # COOCOX STM32 Embedded Pi boards
# HYSTM32_24=1            # HY STM32 2.4 Ebay boards
# HYSTM32_28=1            # HY STM32 2.8 Ebay boards
# HYSTM32_32=1            # HY STM32 3.2 VCT6 Ebay boards
# STM32VLDISCOVERY=1
# STM32F3DISCOVERY=1
# STM32F4DISCOVERY=1
# STM32F429IDISCOVERY=1
# STM32F401CDISCOVERY=1
# MICROBIT=1
# NRF51822DK=1
# NRF52832DK=1            # Ultra low power BLE (bluetooth low energy) enabled SoC. Arm Cortex-M4f processor. With NFC (near field communication).
# CARAMBOLA=1
# DPTBOARD=1              # DPTechnics IoT development board with BlueCherry.io IoT platform integration and DPT-WEB IDE.	
# RASPBERRYPI=1
# BEAGLEBONE=1
# ARIETTA=1
# LPC1768=1 # beta
# LCTECH_STM32F103RBT6=1 # LC Technology STM32F103RBT6 Ebay boards
# ARMINARM=1
# NUCLEOF401RE=1
# NUCLEOF411RE=1
# MINISTM32_STRIVE=1
# MINISTM32_ANGLED_VE=1
# MINISTM32_ANGLED_VG=1
# ESP8266_BOARD=1         # Same as ESP8266_512KB
# ESP8266_4MB=1           # ESP8266 with 4MB flash: 512KB+512KB firmware + 3MB SPIFFS
# ESP8266_2MB=1           # ESP8266 with 2MB flash: 512KB+512KB firmware + 3MB SPIFFS
# ESP8266_1MB=1           # ESP8266 with 1MB flash: 512KB+512KB firmware + 32KB SPIFFS
# ESP8266_512KB=1         # ESP8266 with 512KB flash: 512KB firmware + 32KB SPIFFS
# Or nothing for standard linux compile
#
# Also:
#
# DEBUG=1                 # add debug symbols (-g)
# RELEASE=1               # Force release-style compile (no asserts, etc)
# SINGLETHREAD=1          # Compile single-threaded to make compilation errors easier to find
# BOOTLOADER=1            # make the bootloader (not Espruino)
# PROFILE=1               # Compile with gprof profiling info
# CFILE=test.c            # Compile in the supplied C file
# CPPFILE=test.cpp        # Compile in the supplied C++ file
#
#
# WIZNET=1                # If compiling for a non-linux target that has internet support, use WIZnet support, not TI CC3000

ifndef SINGLETHREAD
MAKEFLAGS=-j5 # multicore
endif


INCLUDE=-I$(ROOT) -I$(ROOT)/targets -I$(ROOT)/src -I$(ROOT)/gen
LIBS=
DEFINES=
CFLAGS=-Wall -Wextra -Wconversion -Werror=implicit-function-declaration
LDFLAGS=-Winline
OPTIMIZEFLAGS=
#-fdiagnostics-show-option - shows which flags can be used with -Werror
DEFINES+=-DGIT_COMMIT=$(shell git log -1 --format="%H")

# Espruino flags...
USE_MATH=1

ifeq ($(shell uname),Darwin)
MACOSX=1
CFLAGS+=-D__MACOSX__
endif

ifeq ($(OS),Windows_NT)
MINGW=1
endif

ifdef RELEASE
# force no asserts to be compiled in
DEFINES += -DNO_ASSERT -DRELEASE
endif

LATEST_RELEASE=$(shell git tag | grep RELEASE_ | sort | tail -1)
# use egrep to count lines instead of wc to avoid whitespace error on Mac
COMMITS_SINCE_RELEASE=$(shell git log --oneline $(LATEST_RELEASE)..HEAD | egrep -c .)
ifneq ($(COMMITS_SINCE_RELEASE),0)
DEFINES += -DBUILDNUMBER=\"$(COMMITS_SINCE_RELEASE)\"
endif


CWD = $(CURDIR)
ROOT = $(CWD)
PRECOMPILED_OBJS=
PLATFORM_CONFIG_FILE=gen/platform_config.h
BASEADDRESS=0x08000000

# ---------------------------------------------------------------------------------
# When adding stuff here, also remember build_pininfo, platform_config.h, jshardware.c
# TODO: Load more of this out of the BOARDNAME.py files if at all possible (see next section)
# ---------------------------------------------------------------------------------

EMBEDDED=1
BOARD=NRF52832DK
OPTIMIZEFLAGS+=-O3

# ----------------------------- end of board defines ------------------------------
# ---------------------------------------------------------------------------------


# ---------------------------------------------------------------------------------
#                                                      Get info out of BOARDNAME.py
# ---------------------------------------------------------------------------------

PROJ_NAME=$(shell python scripts/get_board_info.py $(BOARD) "common.get_board_binary_name(board)"  | sed -e "s/.bin$$//")
ifeq ($(PROJ_NAME),)
$(error Unable to work out binary name (PROJ_NAME))
endif
ifeq ($(BOARD),LINUX)
PROJ_NAME=espruino
endif

ifeq ($(shell python scripts/get_board_info.py $(BOARD) "'bootloader' in board.info and board.info['bootloader']==1"),True)
USE_BOOTLOADER:=1
BOOTLOADER_PROJ_NAME:=bootloader_$(PROJ_NAME)
endif

ifeq ($(shell python scripts/get_board_info.py $(BOARD) "'USB' in board.devices"),True)
USB:=1
endif

ifndef LINUX
FAMILY:=$(shell python scripts/get_board_info.py $(BOARD) "board.chip['family']")
CHIP:=$(shell python scripts/get_board_info.py $(BOARD) "board.chip['part']")
endif

# ---------------------------------------------------------------------------------



# If we're not on Linux and we want internet, we need either CC3000 or WIZnet support
ifdef USE_NET
ifndef LINUX
ifdef WIZNET
USE_WIZNET=1
else
ifeq ($(FAMILY),ESP8266)
USE_ESP8266=1
else
USE_CC3000=1
endif
endif
endif
endif

ifdef DEBUG
#OPTIMIZEFLAGS=-Os -g
ifeq ($(FAMILY),ESP8266)
OPTIMIZEFLAGS=-g -Os
else
OPTIMIZEFLAGS=-g
endif
DEFINES+=-DDEBUG
endif

ifdef PROFILE
OPTIMIZEFLAGS+=-pg
endif

WRAPPERFILE=gen/jswrapper.c
WRAPPERSOURCES = \
src/jswrap_array.c \
src/jswrap_arraybuffer.c \
src/jswrap_date.c \
src/jswrap_error.c \
src/jswrap_espruino.c \
src/jswrap_flash.c \
src/jswrap_functions.c \
src/jswrap_interactive.c \
src/jswrap_io.c \
src/jswrap_json.c \
src/jswrap_modules.c \
src/jswrap_number.c \
src/jswrap_object.c \
src/jswrap_onewire.c \
src/jswrap_pin.c \
src/jswrap_pipe.c \
src/jswrap_process.c \
src/jswrap_serial.c \
src/jswrap_spi_i2c.c \
src/jswrap_stream.c \
src/jswrap_string.c \
src/jswrap_waveform.c

# it is important that _pin comes before stuff which uses
# integers (as the check for int *includes* the chek for pin)

SOURCES = \
src/jslex.c \
src/jsvar.c \
src/jsvariterator.c \
src/jsutils.c \
src/jsnative.c \
src/jsparse.c \
src/jspin.c \
src/jsinteractive.c \
src/jsdevices.c \
src/jstimer.c \
src/jsspi.c \
$(WRAPPERFILE)
CPPSOURCES =

ifdef CFILE
WRAPPERSOURCES += $(CFILE)
endif
ifdef CPPFILE
CPPSOURCES += $(CPPFILE)
endif

ifdef BOOTLOADER
ifndef USE_BOOTLOADER
$(error Using bootloader on device that is not expecting one)
endif
DEFINES+=-DSAVE_ON_FLASH # hack, as without link time optimisation the always_inlines will fail (even though they are not used)
BUILD_LINKER_FLAGS+=--bootloader
PROJ_NAME=$(BOOTLOADER_PROJ_NAME)
WRAPPERSOURCES =
SOURCES = \
targets/stm32_boot/main.c \
targets/stm32_boot/utils.c
 ifndef DEBUG
  OPTIMIZEFLAGS=-Os
 endif
else # !BOOTLOADER but using a bootloader
 ifdef USE_BOOTLOADER
  BUILD_LINKER_FLAGS+=--using_bootloader
  # -k applies bootloader hack for Espruino 1v3 boards
  ifdef MACOSX
    STM32LOADER_FLAGS+=-k -p /dev/tty.usbmodem*
  else
    STM32LOADER_FLAGS+=-k -p /dev/ttyACM0
  endif
  BASEADDRESS=$(shell python scripts/get_board_info.py $(BOARD) "hex(0x08000000+common.get_espruino_binary_address(board))")
 endif
endif

ifdef USB_PRODUCT_ID
DEFINES+=-DUSB_PRODUCT_ID=$(USB_PRODUCT_ID)
endif

ifdef SAVE_ON_FLASH
DEFINES+=-DSAVE_ON_FLASH
else
# If we have enough flash, include the debugger
DEFINES+=-DUSE_DEBUGGER
endif

ifndef BOOTLOADER # ------------------------------------------------------------------------------ DON'T USE IN BOOTLOADER

ifdef USE_FILESYSTEM
DEFINES += -DUSE_FILESYSTEM
INCLUDE += -I$(ROOT)/libs/filesystem
WRAPPERSOURCES += \
libs/filesystem/jswrap_fs.c \
libs/filesystem/jswrap_file.c
ifndef LINUX
INCLUDE += -I$(ROOT)/libs/filesystem/fat_sd
SOURCES += \
libs/filesystem/fat_sd/fattime.c \
libs/filesystem/fat_sd/ff.c \
libs/filesystem/fat_sd/option/unicode.c # for LFN support (see _USE_LFN in ff.h)

ifdef USE_FILESYSTEM_SDIO
DEFINES += -DUSE_FILESYSTEM_SDIO
SOURCES += \
libs/filesystem/fat_sd/sdio_diskio.c \
libs/filesystem/fat_sd/sdio_sdcard.c
else #USE_FILESYSTEM_SDIO
SOURCES += \
libs/filesystem/fat_sd/spi_diskio.c
endif #USE_FILESYSTEM_SDIO
endif #!LINUX
endif #USE_FILESYSTEM

ifdef USE_MATH
DEFINES += -DUSE_MATH
INCLUDE += -I$(ROOT)/libs/math
WRAPPERSOURCES += libs/math/jswrap_math.c
ifndef LINUX
SOURCES += \
libs/math/acosh.c \
libs/math/asin.c \
libs/math/asinh.c \
libs/math/atan.c \
libs/math/atanh.c \
libs/math/cbrt.c \
libs/math/chbevl.c \
libs/math/clog.c \
libs/math/cmplx.c \
libs/math/const.c \
libs/math/cosh.c \
libs/math/drand.c \
libs/math/exp10.c \
libs/math/exp2.c \
libs/math/exp.c \
libs/math/fabs.c \
libs/math/floor.c \
libs/math/isnan.c \
libs/math/log10.c \
libs/math/log2.c \
libs/math/log.c \
libs/math/mtherr.c \
libs/math/polevl.c \
libs/math/pow.c \
libs/math/powi.c \
libs/math/round.c \
libs/math/setprec.c \
libs/math/sin.c \
libs/math/sincos.c \
libs/math/sindg.c \
libs/math/sinh.c \
libs/math/sqrt.c \
libs/math/tan.c \
libs/math/tandg.c \
libs/math/tanh.c \
libs/math/unity.c
#libs/math/mod2pi.c
#libs/math/mtst.c
#libs/math/dtestvec.c
endif
endif

ifdef USE_GRAPHICS
DEFINES += -DUSE_GRAPHICS
INCLUDE += -I$(ROOT)/libs/graphics
WRAPPERSOURCES += libs/graphics/jswrap_graphics.c
SOURCES += \
libs/graphics/bitmap_font_4x6.c \
libs/graphics/graphics.c \
libs/graphics/lcd_arraybuffer.c \
libs/graphics/lcd_js.c

ifdef USE_LCD_SDL
DEFINES += -DUSE_LCD_SDL
SOURCES += libs/graphics/lcd_sdl.c
LIBS += -lSDL
INCLUDE += -I/usr/include/SDL
endif

ifdef USE_LCD_FSMC
DEFINES += -DUSE_LCD_FSMC
SOURCES += libs/graphics/lcd_fsmc.c
endif

endif

ifdef USE_USB_HID
DEFINES += -DUSE_USB_HID
endif

ifdef USE_NET
DEFINES += -DUSE_NET
INCLUDE += -I$(ROOT)/libs/network -I$(ROOT)/libs/network -I$(ROOT)/libs/network/http
WRAPPERSOURCES += \
libs/network/jswrap_net.c \
libs/network/http/jswrap_http.c
SOURCES += \
libs/network/network.c \
libs/network/socketserver.c

# 
WRAPPERSOURCES += libs/network/js/jswrap_jsnetwork.c
INCLUDE += -I$(ROOT)/libs/network/js
SOURCES += \
libs/network/js/network_js.c

 ifdef LINUX
 INCLUDE += -I$(ROOT)/libs/network/linux
 SOURCES += \
 libs/network/linux/network_linux.c
 endif

 ifdef USE_CC3000
 DEFINES += -DUSE_CC3000 -DSEND_NON_BLOCKING
 WRAPPERSOURCES += libs/network/cc3000/jswrap_cc3000.c
 INCLUDE += -I$(ROOT)/libs/network/cc3000
 SOURCES += \
 libs/network/cc3000/network_cc3000.c \
 libs/network/cc3000/board_spi.c \
 libs/network/cc3000/cc3000_common.c \
 libs/network/cc3000/evnt_handler.c \
 libs/network/cc3000/hci.c \
 libs/network/cc3000/netapp.c \
 libs/network/cc3000/nvmem.c \
 libs/network/cc3000/security.c \
 libs/network/cc3000/socket.c \
 libs/network/cc3000/wlan.c
 endif

 ifdef USE_WIZNET
 DEFINES += -DUSE_WIZNET
 WRAPPERSOURCES += libs/network/wiznet/jswrap_wiznet.c
 INCLUDE += -I$(ROOT)/libs/network/wiznet -I$(ROOT)/libs/network/wiznet/Ethernet
 SOURCES += \
 libs/network/wiznet/network_wiznet.c \
 libs/network/wiznet/DNS/dns_parse.c \
 libs/network/wiznet/DNS/dns.c \
 libs/network/wiznet/DHCP/dhcp.c \
 libs/network/wiznet/Ethernet/wizchip_conf.c \
 libs/network/wiznet/Ethernet/socket.c \
 libs/network/wiznet/W5500/w5500.c
 endif

 ifdef USE_ESP8266
 DEFINES += -DUSE_ESP8266
 WRAPPERSOURCES += libs/network/esp8266/jswrap_esp8266.c
 INCLUDE += -I$(ROOT)/libs/network/esp8266
 SOURCES += \
 libs/network/esp8266/network_esp8266.c
 endif
endif

ifdef USE_TV
DEFINES += -DUSE_TV
WRAPPERSOURCES += libs/tv/jswrap_tv.c
INCLUDE += -I$(ROOT)/libs/tv
SOURCES += \
libs/tv/tv.c
endif

ifdef USE_TRIGGER
DEFINES += -DUSE_TRIGGER
WRAPPERSOURCES += libs/trigger/jswrap_trigger.c
INCLUDE += -I$(ROOT)/libs/trigger
SOURCES += \
libs/trigger/trigger.c
endif

ifdef USE_HASHLIB
INCLUDE += -I$(ROOT)/libs/hashlib
WRAPPERSOURCES += \
libs/hashlib/jswrap_hashlib.c
SOURCES += \
libs/hashlib/sha2.c
endif

ifdef USE_WIRINGPI
DEFINES += -DUSE_WIRINGPI
LIBS += -lwiringPi
INCLUDE += -I/usr/local/include -L/usr/local/lib 
endif

ifdef USE_BLUETOOTH
  INCLUDE += -I$(ROOT)/libs/bluetooth
  WRAPPERSOURCES += libs/bluetooth/jswrap_bluetooth.c
endif

endif # BOOTLOADER ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ DON'T USE STUFF ABOVE IN BOOTLOADER

ifdef USB
DEFINES += -DUSB
endif

ifeq ($(FAMILY), NRF51)
  
  NRF5X=1
  NRF5X_SDK_PATH=$(ROOT)/targetlibs/nrf5x/nrf51_sdk
  
  # ARCHFLAGS are shared by both CFLAGS and LDFLAGS.
  ARCHFLAGS = -mcpu=cortex-m0 -mthumb -mabi=aapcs -mfloat-abi=soft # Use nRF51 makefiles provided in SDK as reference.
 
  # nRF51 specific. Main differences in SDK structure are softdevice, uart, delay...
  INCLUDE += -I$(NRF5X_SDK_PATH)/components/softdevice/s110/headers
  SOURCES += $(NRF5X_SDK_PATH)/components/toolchain/system_nrf51.c \
  $(NRF5X_SDK_PATH)/components/drivers_nrf/uart/app_uart_fifo.c

  PRECOMPILED_OBJS+=$(NRF5X_SDK_PATH)/components/toolchain/gcc/gcc_startup_nrf51.o

  DEFINES += -DBOARD_PCA10028  -DNRF51 -DSWI_DISABLE0 -DSOFTDEVICE_PRESENT -DS110 -DBLE_STACK_SUPPORT_REQD # SoftDevice included by default.
  LINKER_FILE = $(NRF5X_SDK_PATH)/components/toolchain/gcc/linker_nrf51_ble_espruino.ld
  
endif # FAMILY == NRF51

ifeq ($(FAMILY), NRF52)
  
  NRF5X=1
  NRF5X_SDK_PATH=$(ROOT)/targetlibs/nrf5x/nrf52_sdk

  # ARCHFLAGS are shared by both CFLAGS and LDFLAGS.
  ARCHFLAGS = -mcpu=cortex-m4 -mthumb -mabi=aapcs -mfloat-abi=hard -mfpu=fpv4-sp-d16 # Use nRF52 makefiles provided in SDK as reference.
 
  # nRF52 specific... Different structure from nRF51 SDK for both delay and uart.
  INCLUDE += -I$(NRF5X_SDK_PATH)/components/softdevice/s132/headers
  INCLUDE += -I$(NRF5X_SDK_PATH)/components/softdevice/s132/headers/nrf52
  INCLUDE += -I$(NRF5X_SDK_PATH)/components/drivers_nrf/delay # this directory doesnt exist in nRF51 SDK.
  SOURCES += $(NRF5X_SDK_PATH)/components/toolchain/system_nrf52.c \
  $(NRF5X_SDK_PATH)/components/drivers_nrf/delay/nrf_delay.c \
  $(NRF5X_SDK_PATH)/components/drivers_nrf/uart/nrf_drv_uart.c \
  $(NRF5X_SDK_PATH)/components/libraries/uart/app_uart_fifo.c

  PRECOMPILED_OBJS+=$(NRF5X_SDK_PATH)/components/toolchain/gcc/gcc_startup_nrf52.o

  DEFINES += -DSWI_DISABLE0 -DSOFTDEVICE_PRESENT -DNRF52 -DBOARD_PCA10036 -DCONFIG_GPIO_AS_PINRESET -DS132 -DBLE_STACK_SUPPORT_REQD
  LINKER_FILE = $(NRF5X_SDK_PATH)/components/toolchain/gcc/linker_nrf52_ble_espruino.ld

endif #FAMILY == NRF52

ifdef NRF5X
  
  ARM = 1
  ARM_HAS_OWN_CMSIS = 1 # Nordic uses its own CMSIS files in its SDK, these are up-to-date.
  INCLUDE += -I$(ROOT)/targetlibs/nrf5x -I$(NRF5X_SDK_PATH)
  
  TEMPLATE_PATH = $(ROOT)/targetlibs/nrf5x # This is where common linker for both nRF51 & nRF52 is stored.
  LDFLAGS += -L$(TEMPLATE_PATH)

  # These files are the Espruino HAL implementation.
  INCLUDE += -I$(ROOT)/targets/nrf5x
  SOURCES +=                              \
  targets/nrf5x/main.c                    \
  targets/nrf5x/jshardware.c              \
  targets/nrf5x/communication_interface.c \
  targets/nrf5x/nrf5x_utils.c

  # Careful here.. All these includes and sources assume a SoftDevice. Not efficeint/clean if softdevice (ble) is not enabled...
  INCLUDE += -I$(NRF5X_SDK_PATH)/examples/ble_peripheral/ble_app_uart/config
  INCLUDE += -I$(NRF5X_SDK_PATH)/components/drivers_nrf/config
  INCLUDE += -I$(NRF5X_SDK_PATH)/examples/bsp
  INCLUDE += -I$(NRF5X_SDK_PATH)/components/libraries/fifo
  INCLUDE += -I$(NRF5X_SDK_PATH)/components/libraries/util
  INCLUDE += -I$(NRF5X_SDK_PATH)/components/drivers_nrf/uart
  INCLUDE += -I$(NRF5X_SDK_PATH)/components/ble/common
  INCLUDE += -I$(NRF5X_SDK_PATH)/components/drivers_nrf/pstorage
  INCLUDE += -I$(NRF5X_SDK_PATH)/components/libraries/uart  # Not nRF51?
  INCLUDE += -I$(NRF5X_SDK_PATH)/components/device
  INCLUDE += -I$(NRF5X_SDK_PATH)/components/libraries/button
  INCLUDE += -I$(NRF5X_SDK_PATH)/components/libraries/timer
  INCLUDE += -I$(NRF5X_SDK_PATH)/components/drivers_nrf/gpiote
  INCLUDE += -I$(NRF5X_SDK_PATH)/components/ble/ble_services/ble_nus
  INCLUDE += -I$(NRF5X_SDK_PATH)/components/drivers_nrf/hal
  INCLUDE += -I$(NRF5X_SDK_PATH)/components/toolchain/gcc
  INCLUDE += -I$(NRF5X_SDK_PATH)/components/toolchain
  INCLUDE += -I$(NRF5X_SDK_PATH)/components/drivers_nrf/common
  INCLUDE += -I$(NRF5X_SDK_PATH)/components/ble/ble_advertising
  INCLUDE += -I$(NRF5X_SDK_PATH)/components/libraries/trace
  INCLUDE += -I$(NRF5X_SDK_PATH)/components/softdevice/common/softdevice_handler

  SOURCES += \
  $(NRF5X_SDK_PATH)/components/libraries/button/app_button.c \
  $(NRF5X_SDK_PATH)/components/libraries/util/app_error.c \
  $(NRF5X_SDK_PATH)/components/libraries/fifo/app_fifo.c \
  $(NRF5X_SDK_PATH)/components/libraries/timer/app_timer.c \
  $(NRF5X_SDK_PATH)/components/libraries/trace/app_trace.c \
  $(NRF5X_SDK_PATH)/components/libraries/util/nrf_assert.c \
  $(NRF5X_SDK_PATH)/components/libraries/uart/retarget.c \
  $(NRF5X_SDK_PATH)/components/drivers_nrf/common/nrf_drv_common.c \
  $(NRF5X_SDK_PATH)/components/drivers_nrf/gpiote/nrf_drv_gpiote.c \
  $(NRF5X_SDK_PATH)/examples/bsp/bsp.c \
  $(NRF5X_SDK_PATH)/components/drivers_nrf/pstorage/pstorage.c \
  $(NRF5X_SDK_PATH)/examples/bsp/bsp_btn_ble.c \
  $(NRF5X_SDK_PATH)/components/ble/common/ble_advdata.c \
  $(NRF5X_SDK_PATH)/components/ble/ble_advertising/ble_advertising.c \
  $(NRF5X_SDK_PATH)/components/ble/common/ble_conn_params.c \
  $(NRF5X_SDK_PATH)/components/ble/ble_services/ble_nus/ble_nus.c \
  $(NRF5X_SDK_PATH)/components/ble/common/ble_srv_common.c \
  $(NRF5X_SDK_PATH)/components/softdevice/common/softdevice_handler/softdevice_handler.c \
  $(NRF5X_SDK_PATH)/components/drivers_nrf/hal/nrf_nvmc.c

endif #NRF5X

ifdef ARM

  ifndef LINKER_FILE # nRF5x targets define their own linker file.
    LINKER_FILE = gen/linker.ld
  endif
  DEFINES += -DARM
  ifndef ARM_HAS_OWN_CMSIS # nRF5x targets do not use the shared CMSIS files.
    INCLUDE += -I$(ROOT)/targetlibs/arm
  endif
  OPTIMIZEFLAGS += -fno-common -fno-exceptions -fdata-sections -ffunction-sections

  # I've no idea why this breaks the bootloader, but it does.
  # Given we've left 10k for it, there's no real reason to enable LTO anyway.
  ifndef BOOTLOADER
	# Enable link-time optimisations (inlining across files)
	OPTIMIZEFLAGS += -flto -fno-fat-lto-objects -Wl,--allow-multiple-definition
	DEFINES += -DLINK_TIME_OPTIMISATION
  endif

  # Limit code size growth via inlining to 8% Normally 30% it seems... This reduces code size while still being able to use -O3
  OPTIMIZEFLAGS += --param inline-unit-growth=6

  export CCPREFIX?=arm-none-eabi-

endif # ARM

PININFOFILE=$(ROOT)/gen/jspininfo
ifdef PININFOFILE
SOURCES += $(PININFOFILE).c
endif


SOURCES += $(WRAPPERSOURCES)
SOURCEOBJS = $(SOURCES:.c=.o) $(CPPSOURCES:.cpp=.o)
OBJS = $(SOURCEOBJS) $(PRECOMPILED_OBJS)


# -ffreestanding -nodefaultlibs -nostdlib -fno-common
# -nodefaultlibs -nostdlib -nostartfiles

# -fdata-sections -ffunction-sections are to help remove unused code
CFLAGS += $(OPTIMIZEFLAGS) -c $(ARCHFLAGS) $(DEFINES) $(INCLUDE)

# -Wl,--gc-sections helps remove unused code
# -Wl,--whole-archive checks for duplicates
ifndef NRF5X
 LDFLAGS += $(OPTIMIZEFLAGS) $(ARCHFLAGS)
else ifdef NRF5X
 LDFLAGS += $(ARCHFLAGS)
 LDFLAGS += --specs=nano.specs -lc -lnosys
endif # NRF5X

ifdef EMBEDDED
DEFINES += -DEMBEDDED
LDFLAGS += -Wl,--gc-sections
endif

ifdef LINKER_FILE
  LDFLAGS += -T$(LINKER_FILE)
endif


export CC=$(CCPREFIX)gcc
export LD=$(CCPREFIX)gcc
export AR=$(CCPREFIX)ar
export AS=$(CCPREFIX)as
export OBJCOPY=$(CCPREFIX)objcopy
export OBJDUMP=$(CCPREFIX)objdump
export GDB=$(CCPREFIX)gdb


.PHONY:  proj

all: 	 proj

ifeq ($(V),1)
        quiet_=
        Q=
else
        quiet_=quiet_
        Q=@
  export SILENT=1
endif


$(WRAPPERFILE): scripts/build_jswrapper.py $(WRAPPERSOURCES)
	@echo Generating JS wrappers
	$(Q)echo WRAPPERSOURCES = $(WRAPPERSOURCES)
	$(Q)echo DEFINES =  $(DEFINES)
	$(Q)python scripts/build_jswrapper.py $(WRAPPERSOURCES) $(DEFINES) -B$(BOARD)

ifdef PININFOFILE
$(PININFOFILE).c $(PININFOFILE).h: scripts/build_pininfo.py
	@echo Generating pin info
	$(Q)python scripts/build_pininfo.py $(BOARD) $(PININFOFILE).c $(PININFOFILE).h
endif

ifndef NRF5X # nRF5x devices use their own linker files that aren't automatically generated.
$(LINKER_FILE): scripts/build_linker.py
	@echo Generating linker scripts
	$(Q)python scripts/build_linker.py $(BOARD) $(LINKER_FILE) $(BUILD_LINKER_FLAGS)
endif # NRF5X

$(PLATFORM_CONFIG_FILE): boards/$(BOARD).py scripts/build_platform_config.py
	@echo Generating platform configs
	$(Q)python scripts/build_platform_config.py $(BOARD)

compile=$(CC) $(CFLAGS) $< -o $@
ifdef FIXED_OBJ_NAME
link=$(LD) $(LDFLAGS) -o espruino $(OBJS) $(LIBS)
else
link=$(LD) $(LDFLAGS) -o $@ $(OBJS) $(LIBS)
endif
# note: link is ignored for the ESP8266
obj_dump=$(OBJDUMP) -x -S $(PROJ_NAME).elf > $(PROJ_NAME).lst
obj_to_bin=$(OBJCOPY) -O $1 $(PROJ_NAME).elf $(PROJ_NAME).$2

quiet_compile= CC $@
quiet_link= LD $@
quiet_obj_dump= GEN $(PROJ_NAME).lst
quiet_obj_to_bin= GEN $(PROJ_NAME).$2

%.o: %.c $(PLATFORM_CONFIG_FILE) $(PININFOFILE).h
	@echo $($(quiet_)compile)
	@$(call compile)

.cpp.o: $(PLATFORM_CONFIG_FILE) $(PININFOFILE).h
	@echo $($(quiet_)compile)
	@$(call compile)

.s.o:
	@echo $($(quiet_)compile)
	@$(call compile)


$(PROJ_NAME).elf: $(OBJS) $(LINKER_FILE)
	@echo $($(quiet_)link)
	@$(call link)

$(PROJ_NAME).lst : $(PROJ_NAME).elf
	@echo $($(quiet_)obj_dump)
	@$(call obj_dump)

$(PROJ_NAME).hex: $(PROJ_NAME).elf
	@echo $(call $(quiet_)obj_to_bin,ihex,hex)
	@$(call obj_to_bin,ihex,hex)

$(PROJ_NAME).srec : $(PROJ_NAME).elf
	@echo $(call $(quiet_)obj_to_bin,srec,srec)
	@$(call obj_to_bin,srec,srec)

$(PROJ_NAME).bin : $(PROJ_NAME).elf
	@echo $(call $(quiet_)obj_to_bin,binary,bin)
	@$(call obj_to_bin,binary,bin)
ifndef TRAVIS
	bash scripts/check_size.sh $(PROJ_NAME).bin
endif

proj: $(PROJ_NAME).lst $(PROJ_NAME).bin $(PROJ_NAME).hex

ifdef ARDUINO_AVR
proj: $(PROJ_NAME).hex
endif

#proj: $(PROJ_NAME).lst $(PROJ_NAME).hex $(PROJ_NAME).srec $(PROJ_NAME).bin

flash: all
ifdef USE_DFU
	sudo dfu-util -a 0 -s 0x08000000 -D $(PROJ_NAME).bin
else ifdef OLIMEXINO_STM32_BOOTLOADER
	echo Olimexino Serial bootloader
	dfu-util -a1 -d 0x1EAF:0x0003 -D $(PROJ_NAME).bin
#else ifdef MBED
	#cp $(PROJ_NAME).bin /media/MBED;sync
else ifdef NUCLEO
	if [ -d "/media/$(USER)/NUCLEO" ]; then cp $(PROJ_NAME).bin /media/$(USER)/NUCLEO;sync; fi
	if [ -d "/media/NUCLEO" ]; then cp $(PROJ_NAME).bin /media/NUCLEO;sync; fi
else
	echo ST-LINK flash
	st-flash --reset write $(PROJ_NAME).bin $(BASEADDRESS)
endif

serialflash: all
	echo STM32 inbuilt serial bootloader, set BOOT0=1, BOOT1=0
	python scripts/stm32loader.py -b 460800 -a $(BASEADDRESS) -ew $(STM32LOADER_FLAGS) $(PROJ_NAME).bin
#	python scripts/stm32loader.py -b 460800 -a $(BASEADDRESS) -ewv $(STM32LOADER_FLAGS) $(PROJ_NAME).bin

ifdef NRF5X # This requires nrfjprog to be working and in your system PATH.
nordic_flash:
	@echo Flashing: s132_nrf52_1.0.0-3.alpha_softdevice.hex
	nrfjprog -f NRF52 --program $(ROOT)/targetlibs/nrf5x/s132_nrf52_1.0.0-3.alpha_softdevice.hex --chiperase --verify
	@echo Flashing: $(ROOT)/$(PROJ_NAME).hex
	nrfjprog -f NRF52 --program $(ROOT)/$(PROJ_NAME).hex --verify
	nrfjprog -f NRF52 --reset
endif

gdb:
	echo "target extended-remote :4242" > gdbinit
	echo "file $(PROJ_NAME).elf" >> gdbinit
	#echo "load" >> gdbinit
	echo "break main" >> gdbinit
	echo "break HardFault_Handler" >> gdbinit
	$(GDB) -x gdbinit
	rm gdbinit

clean:
	@echo Cleaning targets
	$(Q)find . -name *.o | grep -v libmbed | grep -v arm-bcm2708 | xargs rm -f
	$(Q)rm -f $(ROOT)/gen/*.c $(ROOT)/gen/*.h $(ROOT)/gen/*.ld
	$(Q)rm -f $(PROJ_NAME).elf
	$(Q)rm -f $(PROJ_NAME).hex
	$(Q)rm -f $(PROJ_NAME).bin
	$(Q)rm -f $(PROJ_NAME).srec
	$(Q)rm -f $(PROJ_NAME).lst
