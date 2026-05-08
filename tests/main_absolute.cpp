#include "Vtest_absolute.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtest_absolute* top = new Vtest_absolute;
    while (!Verilated::gotFinish()) {
        top->eval();
    }
    delete top;
    return 0;
}
