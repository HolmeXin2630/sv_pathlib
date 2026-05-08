import sv_pathlib_pkg::*;

module test_relative_to;
  int pass_count = 0;
  int fail_count = 0;
  string tmpdir;

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
    string result;
    string tmpfile;
    int fh;

    // Setup: create real temp directories
    tmpfile = "/tmp/.sv_pathlib_test_rel_tmp";
    void'($system($sformatf("mktemp -d > %s", tmpfile)));
    tmpdir = "";
    fh = $fopen(tmpfile, "r");
    if (fh != 0) begin
      void'($fgets(tmpdir, fh));
      $fclose(fh);
      while (tmpdir.len() > 0 && tmpdir[tmpdir.len()-1] == "\n")
        tmpdir = tmpdir.substr(0, tmpdir.len()-2);
    end
    void'($system($sformatf("rm -f %s", tmpfile)));

    void'($system($sformatf("mkdir -p %s/a/b/c %s/a/b/d %s/a/x/y %s/a/b/c/d/e", tmpdir, tmpdir, tmpdir, tmpdir)));

    // Same path -> "."
    result = Path::relative_to({tmpdir, "/a/b/c"}, {tmpdir, "/a/b/c"});
    check("relative_to - same path", result == ".");

    // Child path
    result = Path::relative_to({tmpdir, "/a/b/c/d"}, {tmpdir, "/a/b"});
    check("relative_to - child path", result == "c/d");

    // Sibling path
    result = Path::relative_to({tmpdir, "/a/b/c"}, {tmpdir, "/a/b/d"});
    check("relative_to - sibling path", result == "../c");

    // Up multiple levels then down
    result = Path::relative_to({tmpdir, "/a/x/y"}, {tmpdir, "/a/b/c/d"});
    check("relative_to - up and down", result == "../../../x/y");

    // Root to root
    result = Path::relative_to("/", "/");
    check("relative_to - both root", result == ".");

    // Root to child
    result = Path::relative_to("/tmp", "/");
    check("relative_to - root to child", result == "tmp");

    // Child to root
    result = Path::relative_to("/", "/tmp");
    check("relative_to - child to root", result == "..");

    // Cleanup
    void'($system($sformatf("rm -rf %s", tmpdir)));

    $display("\nRelative_to tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
