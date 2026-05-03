#include "Vtest_path_check_sys.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtest_path_check_sys* top = new Vtest_path_check_sys;
    while (!Verilated::gotFinish()) {
        top->eval();
    }
    delete top;
    return 0;
}
