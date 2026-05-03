#include "Vtest_dir_ops_sys.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtest_dir_ops_sys* top = new Vtest_dir_ops_sys;
    while (!Verilated::gotFinish()) {
        top->eval();
    }
    delete top;
    return 0;
}
