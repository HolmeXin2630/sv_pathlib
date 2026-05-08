#include "Vtest_glob.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtest_glob* top = new Vtest_glob;
    while (!Verilated::gotFinish()) {
        top->eval();
    }
    delete top;
    return 0;
}
