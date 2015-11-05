################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/SEGGER_RTT.c \
../src/SEGGER_RTT_printf.c \
../src/main.c 

OBJS += \
./src/SEGGER_RTT.o \
./src/SEGGER_RTT_printf.o \
./src/main.o 

C_DEPS += \
./src/SEGGER_RTT.d \
./src/SEGGER_RTT_printf.d \
./src/main.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: Cross ARM C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-m0 -mthumb -mfloat-abi=soft -mabi=aapcs -O0 -fmessage-length=0 -Werror  -g3 -DBLE_STACK_SUPPORT_REQD -DSOFTDEVICE_PRESENT -DS110 -DNRF51 -DBOARD_PCA10028 -DNRF51822_QFAA_CA -DDEBUG -I../src -I../config -I../nrf51_sdk/components/libraries/util -I../nrf51_sdk/components/drivers_nrf/pstorage -I../nrf51_sdk/components/toolchain/gcc -I../nrf51_sdk/components/toolchain -I../nrf51_sdk/components/ble/common -I../nrf51_sdk/components/drivers_nrf/common -I../nrf51_sdk/components/ble/ble_advertising -I../nrf51_sdk/components/softdevice/s110/headers -I../nrf51_sdk/components/libraries/trace -I../nrf51_sdk/components/drivers_nrf/gpiote -I../nrf51_sdk/components/ble/device_manager -I../nrf51_sdk/components/drivers_nrf/uart -I../nrf51_sdk/components/device -I../nrf51_sdk/components/softdevice/common/softdevice_handler -I../nrf51_sdk/components/libraries/timer -I../nrf51_sdk/components/drivers_nrf/hal -I../nrf51_sdk/components/libraries/button -I../nrf51_sdk/examples/bsp -std=gnu99 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


