
#include "Vtest_path_parse.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtest_path_parse* top = new Vtest_path_parse;
    while (!Verilated::gotFinish()) {
        top->eval();
    }
    delete top;
    return 0;
}
