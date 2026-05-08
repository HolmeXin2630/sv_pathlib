#include "Vtest_resolve.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtest_resolve* top = new Vtest_resolve;
    while (!Verilated::gotFinish()) {
        top->eval();
    }
    delete top;
    return 0;
}
