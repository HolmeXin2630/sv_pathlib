import path_dpi::*;

module test_path_dpi;
  int pass_count = 0;
  int fail_count = 0;
  string test_dir = "/tmp/sv_pathlib_dpi_test";
  string test_file = "/tmp/sv_pathlib_dpi_test/test.txt";
  string empty_file = "/tmp/sv_pathlib_dpi_test/empty.txt";
  string symlink_file = "/tmp/sv_pathlib_dpi_test/link.txt";
  string copy_file = "/tmp/sv_pathlib_dpi_test/copy.txt";
  string rename_file = "/tmp/sv_pathlib_dpi_test/renamed.txt";
  string empty_dir = "/tmp/sv_pathlib_dpi_test/empty_subdir";
  string nested_dir = "/tmp/sv_pathlib_dpi_test/a/b/c";
  int fh;

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
    // Create test structure
    void'(path_dpi::mkdir(test_dir));

    fh = $fopen(test_file, "w");
    $fwrite(fh, "DPI test content");
    $fclose(fh);

    fh = $fopen(empty_file, "w");
    $fclose(fh);

    // Test exists
    check("exists - dir", path_dpi::exists(test_dir));
    check("exists - file", path_dpi::exists(test_file));
    check("exists - no", !path_dpi::exists("/tmp/nonexistent_xyz"));

    // Test isDir / isFile
    check("isDir", path_dpi::isDir(test_dir));
    check("isFile", path_dpi::isFile(test_file));

    // Test isSymlink
    void'(path_dpi::symlink(test_file, symlink_file));
    check("isSymlink - yes", path_dpi::isSymlink(symlink_file));
    check("isSymlink - no for file", !path_dpi::isSymlink(test_file));

    // Test isEmpty
    check("isEmpty - yes", path_dpi::isEmpty(empty_file));
    check("isEmpty - no for non-empty", !path_dpi::isEmpty(test_file));
    check("isEmpty - no for dir", !path_dpi::isEmpty(test_dir));

    // Test size
    check("size > 0", path_dpi::size(test_file) > 0);
    check("size - empty file", path_dpi::size(empty_file) == 0);
    check("size - nonexistent", path_dpi::size("/tmp/nonexistent_xyz") == -1);

    // Test modified
    check("modified - valid", path_dpi::modified(test_file) > 0);
    check("modified - nonexistent", path_dpi::modified("/tmp/nonexistent_xyz") == -1);

    // Test copy
    path_dpi::copy(test_file, copy_file);
    check("copy - exists after copy", path_dpi::exists(copy_file));
    check("copy - same size", path_dpi::size(copy_file) == path_dpi::size(test_file));

    // Test rename
    path_dpi::rename(test_file, rename_file);
    check("rename - old gone", !path_dpi::exists(test_file));
    check("rename - new exists", path_dpi::exists(rename_file));

    // Test unlink
    path_dpi::unlink(copy_file);
    check("unlink - gone", !path_dpi::exists(copy_file));

    // Test rmdir on empty dir
    void'(path_dpi::mkdir(empty_dir));
    void'(path_dpi::rmdir(empty_dir));
    check("rmdir - empty dir removed", !path_dpi::exists(empty_dir));

    // Test mkdir with nested paths
    void'(path_dpi::mkdir(nested_dir));
    check("mkdir - nested path created", path_dpi::isDir(nested_dir));

    // Cleanup
    path_dpi::unlink(symlink_file);
    path_dpi::unlink(rename_file);
    path_dpi::unlink(empty_file);
    path_dpi::unlink(copy_file);

    $display("\nDPI tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
