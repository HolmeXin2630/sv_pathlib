#include "Vtest_error_sys.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtest_error_sys* top = new Vtest_error_sys;
    while (!Verilated::gotFinish()) {
        top->eval();
    }
    delete top;
    return 0;
}
