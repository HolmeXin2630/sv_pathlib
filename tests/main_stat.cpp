#include "Vtest_stat.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtest_stat* top = new Vtest_stat;
    while (!Verilated::gotFinish()) {
        top->eval();
    }
    delete top;
    return 0;
}
