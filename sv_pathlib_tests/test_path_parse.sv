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
    // Test name()
    check("name - file.txt", Path::name("/tmp/file.txt"), "file.txt");
    check("name - dir/file.sv", Path::name("/home/user/dir/file.sv"), "file.sv");

    // Test stem()
    check("stem - file.txt", Path::stem("/tmp/file.txt"), "file");
    check("stem - archive.tar.gz", Path::stem("/tmp/archive.tar.gz"), "archive.tar");

    // Test extension()
    check("extension - file.txt", Path::extension("/tmp/file.txt"), ".txt");
    check("extension - file.sv", Path::extension("/tmp/file.sv"), ".sv");
    check("extension - no_ext", Path::extension("/tmp/file"), "");

    // Test parent()
    check("parent - /tmp/file.txt", Path::parent("/tmp/file.txt"), "/tmp");
    check("parent - /a/b/c/file", Path::parent("/a/b/c/file"), "/a/b/c");

    // Test joinPath()
    check("joinPath - base + rel", Path::joinPath("/tmp", "file.txt"), "/tmp/file.txt");
    check("joinPath - base + abs", Path::joinPath("/tmp", "/abs/file.txt"), "/abs/file.txt");
    check("joinPath - trailing slash", Path::joinPath("/tmp/", "file.txt"), "/tmp/file.txt");

    // Test withName()
    check("withName - /tmp/old.txt", Path::withName("/tmp/old.txt", "new.txt"), "/tmp/new.txt");
    check("withName - /a/b/c.sv", Path::withName("/a/b/c.sv", "d.sv"), "/a/b/d.sv");

    // Test withSuffix()
    check("withSuffix - .txt to .sv", Path::withSuffix("/tmp/file.txt", ".sv"), "/tmp/file.sv");
    check("withSuffix - no ext", Path::withSuffix("/tmp/file", ".txt"), "/tmp/file.txt");

    // Test isAbsolute()
    check_bit("isAbsolute - /tmp", Path::isAbsolute("/tmp"), 1);
    check_bit("isAbsolute - tmp", Path::isAbsolute("tmp"), 0);
    check_bit("isAbsolute - relative", Path::isAbsolute("a/b/c"), 0);

    $display("\nPath parsing tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
