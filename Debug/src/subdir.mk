################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/SEGGER_RTT.c \
../src/SEGGER_RTT_printf.c \
../src/app_button.c \
../src/app_error.c \
../src/app_timer.c \
../src/app_trace.c \
../src/app_uart.c \
../src/ble_advdata.c \
../src/ble_advertising.c \
../src/ble_conn_params.c \
../src/ble_srv_common.c \
../src/bsp.c \
../src/bsp_btn_ble.c \
../src/device_manager_peripheral.c \
../src/main.c \
../src/nrf_assert.c \
../src/nrf_delay.c \
../src/nrf_drv_common.c \
../src/nrf_drv_gpiote.c \
../src/pstorage.c \
../src/retarget.c \
../src/softdevice_handler.c \
../src/system_nrf51.c 

S_UPPER_SRCS += \
../src/gcc_startup_nrf51.S 

OBJS += \
./src/SEGGER_RTT.o \
./src/SEGGER_RTT_printf.o \
./src/app_button.o \
./src/app_error.o \
./src/app_timer.o \
./src/app_trace.o \
./src/app_uart.o \
./src/ble_advdata.o \
./src/ble_advertising.o \
./src/ble_conn_params.o \
./src/ble_srv_common.o \
./src/bsp.o \
./src/bsp_btn_ble.o \
./src/device_manager_peripheral.o \
./src/gcc_startup_nrf51.o \
./src/main.o \
./src/nrf_assert.o \
./src/nrf_delay.o \
./src/nrf_drv_common.o \
./src/nrf_drv_gpiote.o \
./src/pstorage.o \
./src/retarget.o \
./src/softdevice_handler.o \
./src/system_nrf51.o 

C_DEPS += \
./src/SEGGER_RTT.d \
./src/SEGGER_RTT_printf.d \
./src/app_button.d \
./src/app_error.d \
./src/app_timer.d \
./src/app_trace.d \
./src/app_uart.d \
./src/ble_advdata.d \
./src/ble_advertising.d \
./src/ble_conn_params.d \
./src/ble_srv_common.d \
./src/bsp.d \
./src/bsp_btn_ble.d \
./src/device_manager_peripheral.d \
./src/main.d \
./src/nrf_assert.d \
./src/nrf_delay.d \
./src/nrf_drv_common.d \
./src/nrf_drv_gpiote.d \
./src/pstorage.d \
./src/retarget.d \
./src/softdevice_handler.d \
./src/system_nrf51.d 

S_UPPER_DEPS += \
./src/gcc_startup_nrf51.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: Cross ARM C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-m0 -mthumb -mfloat-abi=soft -mabi=aapcs -O0 -fmessage-length=0 -Werror  -g3 -DBLE_STACK_SUPPORT_REQD -DSOFTDEVICE_PRESENT -DS110 -DNRF51 -DBOARD_PCA10028 -DNRF51822_QFAA_CA -DDEBUG -I../src -I../nrf51_sdk/components/libraries/util -I../nrf51_sdk/components/drivers_nrf/pstorage -I../nrf51_sdk/components/toolchain/gcc -I../nrf51_sdk/components/toolchain -I../nrf51_sdk/components/ble/common -I../nrf51_sdk/components/drivers_nrf/common -I../nrf51_sdk/components/ble/ble_advertising -I../nrf51_sdk/components/softdevice/s110/headers -I../nrf51_sdk/components/drivers_nrf/config -I../nrf51_sdk/components/libraries/trace -I../nrf51_sdk/components/drivers_nrf/gpiote -I../nrf51_sdk/components/ble/device_manager -I../nrf51_sdk/components/drivers_nrf/uart -I../nrf51_sdk/components/device -I../nrf51_sdk/components/softdevice/common/softdevice_handler -I../nrf51_sdk/components/libraries/timer -I../nrf51_sdk/components/drivers_nrf/hal -I../nrf51_sdk/components/libraries/button -I../nrf51_sdk/examples/bsp -std=gnu99 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

src/%.o: ../src/%.S
	@echo 'Building file: $<'
	@echo 'Invoking: Cross ARM GNU Assembler'
	arm-none-eabi-gcc -mcpu=cortex-m0 -mthumb -mfloat-abi=soft -mabi=aapcs -O0 -fmessage-length=0 -Werror  -g3 -x assembler-with-cpp -DBLE_STACK_SUPPORT_REQD -DSOFTDEVICE_PRESENT -DS110 -DNRF51 -DBOARD_PCA10028 -DNRF51822_QFAA_CA -DDEBUG -I../src -I../nrf51_sdk/components/libraries/util -I../nrf51_sdk/components/drivers_nrf/pstorage -I../nrf51_sdk/components/toolchain/gcc -I../nrf51_sdk/components/toolchain -I../nrf51_sdk/components/ble/common -I../nrf51_sdk/components/drivers_nrf/common -I../nrf51_sdk/components/ble/ble_advertising -I../nrf51_sdk/components/softdevice/s110/headers -I../nrf51_sdk/components/drivers_nrf/config -I../nrf51_sdk/components/libraries/trace -I../nrf51_sdk/components/drivers_nrf/gpiote -I../nrf51_sdk/components/ble/device_manager -I../nrf51_sdk/components/drivers_nrf/uart -I../nrf51_sdk/components/device -I../nrf51_sdk/components/softdevice/common/softdevice_handler -I../nrf51_sdk/components/libraries/timer -I../nrf51_sdk/components/drivers_nrf/hal -I../nrf51_sdk/components/libraries/button -I../nrf51_sdk/examples/bsp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


