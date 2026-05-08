import sv_pathlib_pkg::*;

module test_file_io;
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
    string test_file = "/tmp/sv_pathlib_io_test_new.txt";
    string content = "Hello, sv_pathlib!";
    string read_content;

    Path::write_text(test_file, content);
    check("write_text - file exists", Path::exists(test_file), 1);

    read_content = Path::read_text(test_file);
    check("read_text - content matches", read_content, content);

    read_content = Path::read_text("/tmp/nonexistent_xyz_new.txt");
    check("read_text - nonexistent returns empty", read_content, "");

    Path::unlink(test_file);

    $display("\nFile I/O tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
