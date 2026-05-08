import sv_pathlib_pkg::*;

module test_path_parse;
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
    check("name - file.txt", Path::name("/tmp/file.txt"), "file.txt");
    check("name - dir/file.sv", Path::name("/home/user/dir/file.sv"), "file.sv");
    check("stem - file.txt", Path::stem("/tmp/file.txt"), "file");
    check("stem - archive.tar.gz", Path::stem("/tmp/archive.tar.gz"), "archive.tar");
    check("extension - file.txt", Path::extension("/tmp/file.txt"), ".txt");
    check("extension - file.sv", Path::extension("/tmp/file.sv"), ".sv");
    check("extension - no_ext", Path::extension("/tmp/file"), "");
    check("parent - /tmp/file.txt", Path::parent("/tmp/file.txt"), "/tmp");
    check("parent - /a/b/c/file", Path::parent("/a/b/c/file"), "/a/b/c");
    check("join_path - base + rel", Path::join_path("/tmp", "file.txt"), "/tmp/file.txt");
    check("join_path - base + abs", Path::join_path("/tmp", "/abs/file.txt"), "/abs/file.txt");
    check("join_path - trailing slash", Path::join_path("/tmp/", "file.txt"), "/tmp/file.txt");
    check("with_name - /tmp/old.txt", Path::with_name("/tmp/old.txt", "new.txt"), "/tmp/new.txt");
    check("with_suffix - .txt to .sv", Path::with_suffix("/tmp/file.txt", ".sv"), "/tmp/file.sv");
    check_bit("is_absolute - /tmp", Path::is_absolute("/tmp"), 1);
    check_bit("is_absolute - tmp", Path::is_absolute("tmp"), 0);

    $display("\nPath parsing tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
