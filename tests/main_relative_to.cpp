#include "Vtest_relative_to.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtest_relative_to* top = new Vtest_relative_to;
    while (!Verilated::gotFinish()) {
        top->eval();
    }
    delete top;
    return 0;
}
