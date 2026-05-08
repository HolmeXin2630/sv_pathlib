import sv_pathlib_pkg::*;

module test_dir_ops;
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

  // Count newline-separated entries
  function automatic int count_entries(string s);
    int count = 0;
    int i;
    if (s.len() == 0) return 0;
    count = 1;
    for (i = 0; i < s.len(); i++) begin
      if (s[i] == "\n") count++;
    end
    return count;
  endfunction

  initial begin
    string test_dir = "/tmp/sv_pathlib_dirtest_new";
    string entries;
    int fh;

    check("mkdir - create", Path::mkdir(test_dir) == 0);
    check("mkdir - exists after", Path::exists(test_dir));

    fh = $fopen({test_dir, "/file_a.txt"}, "w");
    $fwrite(fh, "a");
    $fclose(fh);
    fh = $fopen({test_dir, "/file_b.txt"}, "w");
    $fwrite(fh, "b");
    $fclose(fh);

    entries = Path::iterdir(test_dir);
    check("iterdir - has entries", count_entries(entries) == 2);

    Path::unlink({test_dir, "/file_a.txt"});
    Path::unlink({test_dir, "/file_b.txt"});
    Path::rmdir(test_dir);

    $display("\nDir ops tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
