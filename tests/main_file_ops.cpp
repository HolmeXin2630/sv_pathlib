#include "Vtest_file_ops.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtest_file_ops* top = new Vtest_file_ops;
    while (!Verilated::gotFinish()) {
        top->eval();
    }
    delete top;
    return 0;
}
