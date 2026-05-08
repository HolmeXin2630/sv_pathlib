#include "Vtest_dir_ops.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtest_dir_ops* top = new Vtest_dir_ops;
    while (!Verilated::gotFinish()) {
        top->eval();
    }
    delete top;
    return 0;
}
