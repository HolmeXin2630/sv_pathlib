#include "Vtest_path_skeleton.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtest_path_skeleton* top = new Vtest_path_skeleton;
    while (!Verilated::gotFinish()) {
        top->eval();
    }
    delete top;
    return 0;
}
