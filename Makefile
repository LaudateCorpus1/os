arch ?= x86_64
kernel := build/kernel-$(arch).bin
iso := build/os-$(arch).iso
toolchain := $(arch)-elf

linker_script := src/arch/$(arch)/linker.ld
grub_cfg := src/arch/$(arch)/grub.cfg
assembly_source_files := $(wildcard src/arch/$(arch)/*.asm)
assembly_object_files := $(patsubst src/arch/$(arch)/%.asm, \
	build/arch/$(arch)/%.o, $(assembly_source_files))
kernel_source_files := $(wildcard src/*.c)
kernel_object_file := build/kernel.o

.PHONY: all clean run vbox iso c

all: $(kernel)

clean:
	@rm -r build

run: $(iso)
	@qemu-system-x86_64 -cdrom $(iso)

vbox: $(iso)
	@VBoxManage controlvm OS reset

iso: $(iso)

$(iso): $(kernel) $(grub_cfg)
	@mkdir -p build/isofiles/boot/grub
	@cp $(kernel) build/isofiles/boot/kernel.bin
	@cp $(grub_cfg) build/isofiles/boot/grub
	@grub-mkrescue -o $(iso) build/isofiles 2> /dev/null
	@rm -r build/isofiles

$(kernel): c $(assembly_object_files) $(linker_script)
	@$(toolchain)-ld -n -T $(linker_script) -o $(kernel) \
		$(assembly_object_files) $(kernel_object_file)

c:
	@$(toolchain)-gcc -c $(kernel_source_files) -o $(kernel_object_file) \
	       -ffreestanding -O2 -Wall -Wextra

# Compile assembly files
build/arch/$(arch)/%.o: src/arch/$(arch)/%.asm
	@mkdir -p $(shell dirname $@)
	@nasm -felf64 $< -o $@
