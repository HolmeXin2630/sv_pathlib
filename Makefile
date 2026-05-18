# Wrapper Makefile — delegates to Verilator Makefile
# Usage:
#   make test_all             — run all tests
#   make test_vcs_all         — run VCS backend mode tests
#   make test_dpi_all         — run DPI backend mode tests
#   make clean                — clean all build artifacts

.PHONY: test_all test_vcs_all test_dpi_all test_clean clean

test_all:
	$(MAKE) -f Makefile.verilator test_all

test_vcs_all:
	$(MAKE) -f Makefile.verilator test_vcs_all

test_dpi_all:
	$(MAKE) -f Makefile.verilator test_dpi_all

test_clean:
	$(MAKE) -f Makefile.verilator test_clean

clean:
	$(MAKE) -f Makefile.verilator clean
