import sv_pathlib_sys_pkg::*;

module test_path_skeleton;
  initial begin
    // Test that Path class exists and can be instantiated
    $display("Path::name: %s", Path::name("/tmp/test.txt"));
    $finish;
  end
endmodule
