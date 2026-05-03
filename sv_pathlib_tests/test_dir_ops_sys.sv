import path_sys::*;

module test_dir_ops_sys;
  int pass_count = 0;
  int fail_count = 0;

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
    string test_dir = "/tmp/sv_pathlib_dirtest";
    int fh;

    // Test mkdir
    check("mkdir - create", path_sys::mkdir(test_dir) == 0, 1);
    check("mkdir - exists after", path_sys::exists(test_dir), 1);
    check("mkdir - isDir after", path_sys::isDir(test_dir), 1);

    // Test mkdir idempotency (-p flag, should succeed on existing dir)
    check("mkdir - idempotent (already exists)", path_sys::mkdir(test_dir) == 0, 1);

    // Test rmdir on non-existent directory
    check("rmdir - non-existent dir", path_sys::rmdir("/tmp/sv_pathlib_nonexistent_xyz") == 0, 0);

    // Test rmdir on non-empty directory (should fail)
    fh = $fopen({test_dir, "/dummy.txt"}, "w");
    $fwrite(fh, "test");
    $fclose(fh);
    check("rmdir - non-empty dir fails", path_sys::rmdir(test_dir) == 0, 0);

    // Clean up the file so rmdir can succeed
    void'(c_system($sformatf("rm -f %s/dummy.txt", test_dir)));

    // Test rmdir
    check("rmdir - remove", path_sys::rmdir(test_dir) == 0, 1);
    check("rmdir - not exists after", path_sys::exists(test_dir), 0);

    // Cleanup: ensure test directory is removed
    void'(c_system($sformatf("rm -rf %s", test_dir)));

    $display("\nDirectory operation tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
