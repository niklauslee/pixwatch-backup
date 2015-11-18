################################################################################
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.init

RM := rm -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include src/subdir.mk
-include nrf51_sdk/components/toolchain/gcc/subdir.mk
-include nrf51_sdk/components/toolchain/subdir.mk
-include nrf51_sdk/components/softdevice/common/softdevice_handler/subdir.mk
-include nrf51_sdk/components/libraries/util/subdir.mk
-include nrf51_sdk/components/libraries/uart/subdir.mk
-include nrf51_sdk/components/libraries/trace/subdir.mk
-include nrf51_sdk/components/libraries/timer/subdir.mk
-include nrf51_sdk/components/libraries/scheduler/subdir.mk
-include nrf51_sdk/components/libraries/gpiote/subdir.mk
-include nrf51_sdk/components/libraries/fifo/subdir.mk
-include nrf51_sdk/components/libraries/button/subdir.mk
-include nrf51_sdk/components/drivers_nrf/uart/subdir.mk
-include nrf51_sdk/components/drivers_nrf/spi_master/subdir.mk
-include nrf51_sdk/components/drivers_nrf/pstorage/subdir.mk
-include nrf51_sdk/components/drivers_nrf/hal/subdir.mk
-include nrf51_sdk/components/drivers_nrf/gpiote/subdir.mk
-include nrf51_sdk/components/drivers_nrf/common/subdir.mk
-include nrf51_sdk/components/ble/device_manager/subdir.mk
-include nrf51_sdk/components/ble/common/subdir.mk
-include nrf51_sdk/components/ble/ble_db_discovery/subdir.mk
-include nrf51_sdk/components/ble/ble_advertising/subdir.mk
-include subdir.mk
-include objects.mk

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(C_DEPS)),)
-include $(C_DEPS)
endif
ifneq ($(strip $(ASM_DEPS)),)
-include $(ASM_DEPS)
endif
ifneq ($(strip $(S_UPPER_DEPS)),)
-include $(S_UPPER_DEPS)
endif
endif

-include ../makefile.defs

# Add inputs and outputs from these tool invocations to the build variables 
SECONDARY_FLASH += \
pixwatch.hex \

SECONDARY_SIZE += \
pixwatch.siz \


# All Target
all: pixwatch.elf secondary-outputs

# Tool invocations
pixwatch.elf: $(OBJS) $(USER_OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: Cross ARM C Linker'
	arm-none-eabi-gcc -mcpu=cortex-m0 -mthumb -mfloat-abi=soft -mabi=aapcs -O0 -fmessage-length=0 -Werror  -g3 -T mem.ld -T sections.ld -L"../ldscripts" -Wl,-Map,"pixwatch.map" --specs=nano.specs -o "pixwatch.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

pixwatch.hex: pixwatch.elf
	@echo 'Invoking: Cross ARM GNU Create Flash Image'
	arm-none-eabi-objcopy -O ihex "pixwatch.elf"  "pixwatch.hex"
	@echo 'Finished building: $@'
	@echo ' '

pixwatch.siz: pixwatch.elf
	@echo 'Invoking: Cross ARM GNU Print Size'
	arm-none-eabi-size --format=berkeley "pixwatch.elf"
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(SECONDARY_SIZE)$(OBJS)$(C_DEPS)$(ASM_DEPS)$(SECONDARY_FLASH)$(S_UPPER_DEPS) pixwatch.elf
	-@echo ' '

secondary-outputs: $(SECONDARY_FLASH) $(SECONDARY_SIZE)

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets
