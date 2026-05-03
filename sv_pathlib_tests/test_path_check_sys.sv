import sv_pathlib_pkg::*;
import path_sys::*;

module test_path_check_sys;
  int pass_count = 0;
  int fail_count = 0;
  int fh;

  task automatic check(string test_name, bit actual, bit expected);
    if (actual == expected) begin
      $display("[PASS] %s: got %b", test_name, actual);
      pass_count++;
    end else begin
      $display("[FAIL] %s: expected %b, got %b", test_name, expected, actual);
      fail_count++;
    end
  endtask

  initial begin
    // Create test files/dirs
    void'(path_sys::mkdir("/tmp/sv_pathlib_test"));
    void'(path_sys::mkdir("/tmp/sv_pathlib_test/subdir"));

    // Write test file
    fh = $fopen("/tmp/sv_pathlib_test/test.txt", "w");
    $fwrite(fh, "test content");
    $fclose(fh);

    // Write empty file
    fh = $fopen("/tmp/sv_pathlib_test/empty.txt", "w");
    $fclose(fh);

    // Test exists()
    check("exists - /tmp", path_sys::exists("/tmp"), 1);
    check("exists - nonexistent", path_sys::exists("/tmp/nonexistent_xyz"), 0);

    // Test is_dir()
    check("is_dir - /tmp", path_sys::is_dir("/tmp"), 1);
    check("is_dir - file", path_sys::is_dir("/tmp/sv_pathlib_test/test.txt"), 0);

    // Test is_file()
    check("is_file - file", path_sys::is_file("/tmp/sv_pathlib_test/test.txt"), 1);
    check("is_file - dir", path_sys::is_file("/tmp/sv_pathlib_test"), 0);

    // Test is_empty()
    check("is_empty - empty file", path_sys::is_empty("/tmp/sv_pathlib_test/empty.txt"), 1);
    check("is_empty - non-empty file", path_sys::is_empty("/tmp/sv_pathlib_test/test.txt"), 0);

    // Test is_symlink()
    void'(c_system("ln -s /tmp/sv_pathlib_test/test.txt /tmp/sv_pathlib_test/link.txt"));
    check("is_symlink - symlink", path_sys::is_symlink("/tmp/sv_pathlib_test/link.txt"), 1);
    check("is_symlink - regular file", path_sys::is_symlink("/tmp/sv_pathlib_test/test.txt"), 0);

    // Test rmdir()
    void'(path_sys::mkdir("/tmp/sv_pathlib_test/rmdir_test"));
    check("rmdir - dir exists before", path_sys::exists("/tmp/sv_pathlib_test/rmdir_test"), 1);
    check("rmdir - success", path_sys::rmdir("/tmp/sv_pathlib_test/rmdir_test") == 0, 1);
    check("rmdir - dir removed", path_sys::exists("/tmp/sv_pathlib_test/rmdir_test"), 0);

    $display("\nFile check tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
