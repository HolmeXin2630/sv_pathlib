import sv_pathlib_pkg::*;
import path_sys::*;

module test_unified;
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

  task automatic check_bit(string test_name, bit actual, bit expected);
    if (actual == expected) begin
      $display("[PASS] %s: got %0d", test_name, actual);
      pass_count++;
    end else begin
      $display("[FAIL] %s: expected %0d, got %0d", test_name, expected, actual);
      fail_count++;
    end
  endtask

  initial begin
    // Test Path class (static methods)
    check("Path::name", Path::name("/tmp/test.txt"), "test.txt");
    check("Path::parent", Path::parent("/tmp/test.txt"), "/tmp");
    check("Path::join", Path::join_path("/tmp", "test.txt"), "/tmp/test.txt");

    // Test path_sys (file operations)
    path_sys::write_text("/tmp/unified_test.txt", "unified content");
    check("path_sys::read_text", path_sys::read_text("/tmp/unified_test.txt"), "unified content");
    check_bit("path_sys::exists", path_sys::exists("/tmp/unified_test.txt"), 1);

    // Cleanup
    path_sys::unlink("/tmp/unified_test.txt");

    $display("\nUnified tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
