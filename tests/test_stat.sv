import sv_pathlib_pkg::*;

module test_stat;
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

  initial begin
    stat_t s;
    string test_file = "/tmp/sv_pathlib_stat_test.txt";
    int fh;

    fh = $fopen(test_file, "w");
    $fwrite(fh, "stat test content");
    $fclose(fh);

    s = Path::stat(test_file);
    check("stat - size > 0", s.st_size > 0);
    check("stat - mtime > 0", s.st_mtime > 0);
    check("stat - atime > 0", s.st_atime > 0);

    s = Path::stat("/tmp/nonexistent_xyz");
    check("stat - nonexistent size == -1", s.st_size == -1);

    Path::unlink(test_file);

    $display("\nStat tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
