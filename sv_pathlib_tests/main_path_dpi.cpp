#include "Vtest_path_dpi.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtest_path_dpi* top = new Vtest_path_dpi;
    while (!Verilated::gotFinish()) {
        top->eval();
    }
    delete top;
    return 0;
}
