import sv_pathlib_pkg::*;

module test_resolve;
  int pass_count = 0;
  int fail_count = 0;

  task automatic check(string test_name, string actual, string expected);
    if (actual == expected) begin
      $display("[PASS] %s: got '%s'", test_name, actual);
      pass_count++;
    end else begin
      $display("[FAIL] %s: expected '%s', got '%s'", test_name, expected, actual);
      fail_count++;
    end
  endtask

  initial begin
    check("resolve - /a/b/../c", Path::resolve("/a/b/../c"), "/a/c");
    check("resolve - /a/b/./c", Path::resolve("/a/b/./c"), "/a/b/c");
    check("resolve - /a/b/../c/./d", Path::resolve("/a/b/../c/./d"), "/a/c/d");
    check("resolve - a/b/../c", Path::resolve("a/b/../c"), "a/c");
    check("resolve - /", Path::resolve("/"), "/");
    check("resolve - .", Path::resolve("."), ".");
    check("resolve - ..", Path::resolve(".."), "..");
    check("resolve - /a/../../b", Path::resolve("/a/../../b"), "/b");

    $display("\nResolve tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
