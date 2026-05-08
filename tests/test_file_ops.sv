import sv_pathlib_pkg::*;

module test_file_ops;
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

  task automatic check_str(string test_name, string actual, string expected);
    if (actual == expected) begin
      $display("[PASS] %s", test_name);
      pass_count++;
    end else begin
      $display("[FAIL] %s: expected '%s', got '%s'", test_name, expected, actual);
      fail_count++;
    end
  endtask

  initial begin
    string src = "/tmp/sv_pathlib_ops_src_new.txt";
    string dst = "/tmp/sv_pathlib_ops_dst_new.txt";
    string renamed = "/tmp/sv_pathlib_ops_renamed_new.txt";

    Path::write_text(src, "test content for ops");

    Path::copy(src, dst);
    check("copy - dest exists", Path::exists(dst));
    check_str("copy - content matches", Path::read_text(dst), "test content for ops");

    Path::rename(dst, renamed);
    check("rename - new name exists", Path::exists(renamed));
    check("rename - old name gone", !Path::exists(dst));

    check("size - correct", Path::size(renamed) > 0);
    check("modified - returns positive timestamp", Path::modified(renamed) > 0);

    Path::unlink(src);
    Path::unlink(renamed);

    $display("\nFile operation tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
