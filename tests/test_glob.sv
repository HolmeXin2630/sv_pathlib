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

  initial begin
    string test_dir = "/tmp/sv_pathlib_glob_test";
    queue<string> results;
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
    check("glob *.sv - found 2", results.size() == 2);

    results = Path::glob(test_dir, "*.txt");
    check("glob *.txt - found 1", results.size() == 1);

    void'(Path::mkdir({test_dir, "/sub"}));
    fh = $fopen({test_dir, "/sub/nested.sv"}, "w");
    $fwrite(fh, "test");
    $fclose(fh);
    results = Path::rglob(test_dir, "*.sv");
    check("rglob *.sv - found 3 (including nested)", results.size() == 3);
`else
    results = Path::glob(test_dir, "*.sv");
    check("glob VCS mode - returns empty", results.size() == 0);
`endif

    void'($system($sformatf("rm -rf %s", test_dir)));

    $display("\nGlob tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
