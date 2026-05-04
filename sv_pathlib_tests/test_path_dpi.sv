import sv_pathlib_dpi_pkg::*;

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
    void'(Path::mkdir(test_dir));

    fh = $fopen(test_file, "w");
    $fwrite(fh, "DPI test content");
    $fclose(fh);

    fh = $fopen(empty_file, "w");
    $fclose(fh);

    // Test exists
    check("exists - dir", Path::exists(test_dir));
    check("exists - file", Path::exists(test_file));
    check("exists - no", !Path::exists("/tmp/nonexistent_xyz"));

    // Test is_dir / is_file
    check("is_dir", Path::is_dir(test_dir));
    check("is_file", Path::is_file(test_file));

    // Test is_symlink
    void'(Path::symlink(test_file, symlink_file));
    check("is_symlink - yes", Path::is_symlink(symlink_file));
    check("is_symlink - no for file", !Path::is_symlink(test_file));

    // Test is_empty
    check("is_empty - yes", Path::is_empty(empty_file));
    check("is_empty - no for non-empty", !Path::is_empty(test_file));
    check("is_empty - no for dir", !Path::is_empty(test_dir));

    // Test size
    check("size > 0", Path::size(test_file) > 0);
    check("size - empty file", Path::size(empty_file) == 0);
    check("size - nonexistent", Path::size("/tmp/nonexistent_xyz") == -1);

    // Test modified
    check("modified - valid", Path::modified(test_file) > 0);
    check("modified - nonexistent", Path::modified("/tmp/nonexistent_xyz") == -1);

    // Test copy
    Path::copy(test_file, copy_file);
    check("copy - exists after copy", Path::exists(copy_file));
    check("copy - same size", Path::size(copy_file) == Path::size(test_file));

    // Test rename
    Path::rename(test_file, rename_file);
    check("rename - old gone", !Path::exists(test_file));
    check("rename - new exists", Path::exists(rename_file));

    // Test unlink
    Path::unlink(copy_file);
    check("unlink - gone", !Path::exists(copy_file));

    // Test rmdir on empty dir
    void'(Path::mkdir(empty_dir));
    void'(Path::rmdir(empty_dir));
    check("rmdir - empty dir removed", !Path::exists(empty_dir));

    // Test mkdir with nested paths
    void'(Path::mkdir(nested_dir));
    check("mkdir - nested path created", Path::is_dir(nested_dir));

    // Cleanup
    Path::unlink(symlink_file);
    Path::unlink(rename_file);
    Path::unlink(empty_file);
    Path::unlink(copy_file);

    $display("\nDPI tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
