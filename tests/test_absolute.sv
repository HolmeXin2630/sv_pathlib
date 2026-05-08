import sv_pathlib_pkg::*;

module test_absolute;
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
    string result;

    // Absolute path stays absolute (normalized)
    result = Path::absolute("/a/b/c");
    check("absolute - already absolute", result == "/a/b/c");

    // Normalize dot and dotdot
    result = Path::absolute("/a/b/../c");
    check("absolute - normalize dotdot", result == "/a/c");

    result = Path::absolute("/a/./b");
    check("absolute - normalize dot", result == "/a/b");

    // Relative path gets cwd prefix
    result = Path::absolute("foo/bar");
    check("absolute - relative path has cwd prefix", result.len() > 8);

    // Single component
    result = Path::absolute("foo");
    check("absolute - single component", result.len() > 3);

    $display("\nAbsolute tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
