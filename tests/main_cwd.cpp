#include "Vtest_cwd.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtest_cwd* top = new Vtest_cwd;
    while (!Verilated::gotFinish()) {
        top->eval();
    }
    delete top;
    return 0;
}
