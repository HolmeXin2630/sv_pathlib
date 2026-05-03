#include "Vtest_unified.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtest_unified* top = new Vtest_unified;
    while (!Verilated::gotFinish()) {
        top->eval();
    }
    delete top;
    return 0;
}
