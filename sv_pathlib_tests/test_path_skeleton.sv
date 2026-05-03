import sv_pathlib_pkg::*;

module test_path_skeleton;
  initial begin
    // Test that Path class exists and can be instantiated
    Path p = new("/tmp/test.txt");
    $display("Path created: %s", p.str());
    $finish;
  end
endmodule
