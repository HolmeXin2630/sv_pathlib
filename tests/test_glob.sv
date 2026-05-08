import sv_pathlib_pkg::*;

module test_glob;
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
    string test_dir = "/tmp/sv_pathlib_glob_test";
    string results;
    int fh;

    void'(Path::mkdir(test_dir));
    fh = $fopen({test_dir, "/test.sv"}, "w");
    $fwrite(fh, "test");
    $fclose(fh);
    fh = $fopen({test_dir, "/test.txt"}, "w");
    $fwrite(fh, "test");
    $fclose(fh);
    fh = $fopen({test_dir, "/other.sv"}, "w");
    $fwrite(fh, "test");
    $fclose(fh);

`ifdef SV_PATHLIB_USE_DPI
    results = Path::glob(test_dir, "*.sv");
    check("glob *.sv - found 2", count_entries(results) == 2);

    results = Path::glob(test_dir, "*.txt");
    check("glob *.txt - found 1", count_entries(results) == 1);

    void'(Path::mkdir({test_dir, "/sub"}));
    fh = $fopen({test_dir, "/sub/nested.sv"}, "w");
    $fwrite(fh, "test");
    $fclose(fh);
    results = Path::rglob(test_dir, "*.sv");
    check("rglob *.sv - found 3 (including nested)", count_entries(results) == 3);
`else
    results = Path::glob(test_dir, "*.sv");
    check("glob VCS mode - returns empty", results.len() == 0);
`endif

    void'($system($sformatf("rm -rf %s", test_dir)));

    $display("\nGlob tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
