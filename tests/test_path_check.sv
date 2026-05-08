import sv_pathlib_pkg::*;

module test_path_check;
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
    void'(Path::mkdir("/tmp/sv_pathlib_test_new"));
    void'(Path::mkdir("/tmp/sv_pathlib_test_new/subdir"));

    fh = $fopen("/tmp/sv_pathlib_test_new/test.txt", "w");
    $fwrite(fh, "test content");
    $fclose(fh);

    fh = $fopen("/tmp/sv_pathlib_test_new/empty.txt", "w");
    $fclose(fh);

    check("exists - /tmp", Path::exists("/tmp"), 1);
    check("exists - nonexistent", Path::exists("/tmp/nonexistent_xyz_new"), 0);
    check("is_dir - /tmp", Path::is_dir("/tmp"), 1);
    check("is_dir - file", Path::is_dir("/tmp/sv_pathlib_test_new/test.txt"), 0);
    check("is_file - file", Path::is_file("/tmp/sv_pathlib_test_new/test.txt"), 1);
    check("is_file - dir", Path::is_file("/tmp/sv_pathlib_test_new"), 0);
    check("is_empty - empty file", Path::is_empty("/tmp/sv_pathlib_test_new/empty.txt"), 1);
    check("is_empty - non-empty file", Path::is_empty("/tmp/sv_pathlib_test_new/test.txt"), 0);

    void'($system("ln -s /tmp/sv_pathlib_test_new/test.txt /tmp/sv_pathlib_test_new/link.txt"));
    check("is_symlink - symlink", Path::is_symlink("/tmp/sv_pathlib_test_new/link.txt"), 1);
    check("is_symlink - regular file", Path::is_symlink("/tmp/sv_pathlib_test_new/test.txt"), 0);

    void'(Path::mkdir("/tmp/sv_pathlib_test_new/rmdir_test"));
    check("rmdir - dir exists before", Path::exists("/tmp/sv_pathlib_test_new/rmdir_test"), 1);
    check("rmdir - success", Path::rmdir("/tmp/sv_pathlib_test_new/rmdir_test") == 0, 1);
    check("rmdir - dir removed", Path::exists("/tmp/sv_pathlib_test_new/rmdir_test"), 0);

    $display("\nFile check tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
