#include "Vtest_hello.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtest_hello *top = new Vtest_hello;
    while (!Verilated::gotFinish()) {
        top->eval();
    }
    delete top;
    return 0;
}
