import path_sys::*;

module test_file_ops_sys;
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

  task automatic check_str(string test_name, string actual, string expected);
    if (actual == expected) begin
      $display("[PASS] %s", test_name);
      pass_count++;
    end else begin
      $display("[FAIL] %s: expected '%s', got '%s'", test_name, expected, actual);
      fail_count++;
    end
  endtask

  initial begin
    string src = "/tmp/sv_pathlib_ops_src.txt";
    string dst = "/tmp/sv_pathlib_ops_dst.txt";
    string renamed = "/tmp/sv_pathlib_ops_renamed.txt";

    // Create source file
    path_sys::write_text(src, "test content for ops");

    // Test copy
    path_sys::copy(src, dst);
    check("copy - dest exists", path_sys::exists(dst));
    check_str("copy - content matches", path_sys::read_text(dst), "test content for ops");

    // Test rename
    path_sys::rename(dst, renamed);
    check("rename - new name exists", path_sys::exists(renamed));
    check("rename - old name gone", !path_sys::exists(dst));

    // Test size
    check("size - correct", path_sys::size(renamed) > 0);

    // Test modified
    check("modified - returns positive timestamp", path_sys::modified(renamed) > 0);

    // Cleanup
    path_sys::unlink(src);
    path_sys::unlink(renamed);

    $display("\nFile operation tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
