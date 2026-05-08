#include "Vtest_path_check.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtest_path_check* top = new Vtest_path_check;
    while (!Verilated::gotFinish()) {
        top->eval();
    }
    delete top;
    return 0;
}
