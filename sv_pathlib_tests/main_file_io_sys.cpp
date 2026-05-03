#include "Vtest_file_io_sys.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtest_file_io_sys* top = new Vtest_file_io_sys;
    while (!Verilated::gotFinish()) {
        top->eval();
    }
    delete top;
    return 0;
}
