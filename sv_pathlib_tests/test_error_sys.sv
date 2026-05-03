import path_sys::*;

module test_error_sys;
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
    string content;
    string test_file = "/tmp/test_read_existing.txt";
    string test_content = "hello world\nline two";

    // Test readText on existing file
    path_sys::writeText(test_file, test_content);
    content = path_sys::readText(test_file);
    check("readText existing - returns content", content == test_content);
    check("readText existing - no error", path_sys::getLastErrorCode() == 0);
    path_sys::unlink(test_file);

    // Test readText on nonexistent file
    path_sys::clearError();
    content = path_sys::readText("/tmp/nonexistent_xyz.txt");
    check("readText nonexistent - returns empty", content == "");
    check("readText nonexistent - error set", path_sys::getLastErrorCode() != 0);

    // Test copy nonexistent file
    path_sys::clearError();
    path_sys::copy("/tmp/nonexistent_xyz.txt", "/tmp/dest.txt");
    check("copy nonexistent - error set", path_sys::getLastErrorCode() != 0);

    $display("\nError handling tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
