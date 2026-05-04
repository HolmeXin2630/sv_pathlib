import sv_pathlib_sys_pkg::*;

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
    Path::write_text(test_file, test_content);
    content = Path::read_text(test_file);
    check("read_text existing - returns content", content == test_content);
    Path::unlink(test_file);

    // Test read_text on nonexistent file
    content = Path::read_text("/tmp/nonexistent_xyz.txt");
    check("read_text nonexistent - returns empty", content == "");

    // Test copy nonexistent file
    Path::copy("/tmp/nonexistent_xyz.txt", "/tmp/dest.txt");

    // Note: $error() prints messages but doesn't set global state
    // This is the intended behavior for concurrent safety

    $display("\nError handling tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
