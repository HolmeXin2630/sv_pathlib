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

    // Test read_text on existing file
    path_sys::write_text(test_file, test_content);
    content = path_sys::read_text(test_file);
    check("read_text existing - returns content", content == test_content);
    check("read_text existing - no error", path_sys::get_last_error_code() == 0);
    path_sys::unlink(test_file);

    // Test read_text on nonexistent file
    path_sys::clear_error();
    content = path_sys::read_text("/tmp/nonexistent_xyz.txt");
    check("read_text nonexistent - returns empty", content == "");
    check("read_text nonexistent - error set", path_sys::get_last_error_code() != 0);

    // Test copy nonexistent file
    path_sys::clear_error();
    path_sys::copy("/tmp/nonexistent_xyz.txt", "/tmp/dest.txt");
    check("copy nonexistent - error set", path_sys::get_last_error_code() != 0);

    $display("\nError handling tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
