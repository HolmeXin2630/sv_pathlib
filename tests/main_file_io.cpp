#include "Vtest_file_io.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtest_file_io* top = new Vtest_file_io;
    while (!Verilated::gotFinish()) {
        top->eval();
    }
    delete top;
    return 0;
}
