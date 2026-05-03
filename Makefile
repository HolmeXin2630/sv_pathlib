# sv_pathlib Makefile
VERILATOR = verilator
VERILATOR_FLAGS = --cc --exe --build

# Test targets
.PHONY: test_hello test_skeleton test_path_parse test_path_check_sys test_dir_ops_sys test_file_io_sys test_file_ops_sys test_error_sys test_path_dpi test_unified test_clean clean

test_hello:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		sv_pathlib_tests/test_hello.sv \
		sv_pathlib_tests/main.cpp \
		--top-module test_hello \
		--Mdir obj_dir_hello \
		-o test_hello
	./obj_dir_hello/test_hello

test_skeleton:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		sv_pathlib_pkg.sv path.sv \
		sv_pathlib_tests/test_path_skeleton.sv \
		sv_pathlib_tests/main_skeleton.cpp \
		--top-module test_path_skeleton \
		--Mdir obj_dir_skeleton \
		-o test_skeleton
	./obj_dir_skeleton/test_skeleton

test_path_parse:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		sv_pathlib_pkg.sv path.sv \
		sv_pathlib_tests/test_path_parse.sv \
		sv_pathlib_tests/main_path_parse.cpp \
		--top-module test_path_parse \
		--Mdir obj_dir_path_parse \
		-o test_path_parse
	./obj_dir_path_parse/test_path_parse

test_path_check_sys:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		sv_pathlib_pkg.sv path.sv \
		sv_pathlib_sys/path_sys.sv \
		sv_pathlib_tests/test_path_check_sys.sv \
		sv_pathlib_tests/main_path_check_sys.cpp \
		sv_pathlib_dpi/dpi_system.c \
		--top-module test_path_check_sys \
		--Mdir obj_dir_path_check_sys \
		-o test_path_check_sys
	./obj_dir_path_check_sys/test_path_check_sys

test_dir_ops_sys:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		sv_pathlib_sys/path_sys.sv \
		sv_pathlib_tests/test_dir_ops_sys.sv \
		sv_pathlib_tests/main_dir_ops_sys.cpp \
		sv_pathlib_dpi/dpi_system.c \
		--top-module test_dir_ops_sys \
		--Mdir obj_dir_dir_ops_sys \
		-o test_dir_ops_sys
	./obj_dir_dir_ops_sys/test_dir_ops_sys

test_file_io_sys:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		sv_pathlib_sys/path_sys.sv \
		sv_pathlib_tests/test_file_io_sys.sv \
		sv_pathlib_tests/main_file_io_sys.cpp \
		sv_pathlib_dpi/dpi_system.c \
		--top-module test_file_io_sys \
		--Mdir obj_dir_file_io_sys \
		-o test_file_io_sys
	./obj_dir_file_io_sys/test_file_io_sys

test_file_ops_sys:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		sv_pathlib_sys/path_sys.sv \
		sv_pathlib_tests/test_file_ops_sys.sv \
		sv_pathlib_tests/main_file_ops_sys.cpp \
		sv_pathlib_dpi/dpi_system.c \
		--top-module test_file_ops_sys \
		--Mdir obj_dir_file_ops_sys \
		-o test_file_ops_sys
	./obj_dir_file_ops_sys/test_file_ops_sys

test_error_sys:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		sv_pathlib_sys/path_sys.sv \
		sv_pathlib_tests/test_error_sys.sv \
		sv_pathlib_tests/main_error_sys.cpp \
		sv_pathlib_dpi/dpi_system.c \
		--top-module test_error_sys \
		--Mdir obj_dir_error_sys \
		-o test_error_sys
	./obj_dir_error_sys/test_error_sys

test_path_dpi:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		sv_pathlib_dpi/path_dpi.sv \
		sv_pathlib_tests/test_path_dpi.sv \
		sv_pathlib_tests/main_path_dpi.cpp \
		sv_pathlib_dpi/path_dpi_impl.cc \
		--top-module test_path_dpi \
		--Mdir obj_dir_path_dpi \
		-o test_path_dpi
	./obj_dir_path_dpi/test_path_dpi

test_unified:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		sv_pathlib_pkg.sv path.sv \
		sv_pathlib_sys/path_sys.sv \
		sv_pathlib_tests/test_unified.sv \
		sv_pathlib_tests/main_unified.cpp \
		sv_pathlib_dpi/dpi_system.c \
		--top-module test_unified \
		--Mdir obj_dir_unified \
		-o test_unified
	./obj_dir_unified/test_unified

test_all: test_hello test_skeleton test_path_parse test_path_check_sys test_dir_ops_sys test_file_io_sys test_file_ops_sys test_error_sys test_path_dpi test_unified
	@echo "All tests passed!"

test_clean:
	rm -rf obj_dir_*

clean: test_clean
	rm -rf obj_dir*
