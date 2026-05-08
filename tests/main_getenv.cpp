#include "Vtest_getenv.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtest_getenv* top = new Vtest_getenv;
    while (!Verilated::gotFinish()) {
        top->eval();
    }
    delete top;
    return 0;
}
