import sv_pathlib_pkg::*;

module test_getenv;
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
    string val;

    // Use an existing env var
    val = Path::getenv("HOME");
    check("getenv - HOME not empty", val.len() > 0);

    // Nonexistent var should return empty
    val = Path::getenv("SV_PATHLIB_NONEXISTENT_XYZ_12345");
    check("getenv - nonexistent var returns empty", val.len() == 0);

    $display("\nGetenv tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
