import sv_pathlib_pkg::*;

module test_cwd;
  int pass_count = 0;
  int fail_count = 0;

  task automatic check(string test_name, bit condition);
    if (condition) begin
      $display("[PASS] %s", test_name);
      pass_count++;
    end else begin
      $display("[FAIL] %s", test_name);
      fail_count++;
    end
  endtask

  initial begin
    string cwd;
    cwd = Path::cwd();
    check("cwd - not empty", cwd.len() > 0);
    check("cwd - starts with /", cwd[0] == "/");

    $display("\nCWD tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
