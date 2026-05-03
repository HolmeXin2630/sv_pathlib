import path_sys::*;

module test_file_io_sys;
  int pass_count = 0;
  int fail_count = 0;

  task automatic check(string test_name, string actual, string expected);
    if (actual == expected) begin
      $display("[PASS] %s", test_name);
      pass_count++;
    end else begin
      $display("[FAIL] %s: expected '%s', got '%s'", test_name, expected, actual);
      fail_count++;
    end
  endtask

  initial begin
    string test_file = "/tmp/sv_pathlib_io_test.txt";
    string content = "Hello, sv_pathlib!";
    string read_content;

    // Test writeText
    path_sys::writeText(test_file, content);
    check("writeText - file exists", path_sys::exists(test_file), 1);

    // Test readText
    read_content = path_sys::readText(test_file);
    check("readText - content matches", read_content, content);

    // Test readText - nonexistent file
    read_content = path_sys::readText("/tmp/nonexistent_xyz.txt");
    check("readText - nonexistent returns empty", read_content, "");

    // Cleanup
    path_sys::unlink(test_file);

    $display("\nFile I/O tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
