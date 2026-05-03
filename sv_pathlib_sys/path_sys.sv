/* verilator lint_off IMPLICITSTATIC */
package path_sys;
  import "DPI-C" function int c_system(input string cmd);
  import "DPI-C" function void c_write_text(input string path, input string content);
  import "DPI-C" function void c_unlink(input string path);
  import "DPI-C" function longint c_file_size(input string path);
  import "DPI-C" function longint c_file_mtime(input string path);

  // Error handling
  string last_error_msg = "";
  int last_error_code = 0;

  function void clear_error();
    last_error_msg = "";
    last_error_code = 0;
  endfunction

  function string get_last_error();
    return last_error_msg;
  endfunction

  function int get_last_error_code();
    return last_error_code;
  endfunction

  function void set_error(int code, string msg);
    last_error_code = code;
    last_error_msg = msg;
  endfunction

  function bit exists(string path);
    return c_system($sformatf("test -e %s", path)) == 0;
  endfunction

  function bit is_file(string path);
    return c_system($sformatf("test -f %s", path)) == 0;
  endfunction

  function bit is_dir(string path);
    return c_system($sformatf("test -d %s", path)) == 0;
  endfunction

  function bit is_symlink(string path);
    return c_system($sformatf("test -L %s", path)) == 0;
  endfunction

  function bit is_empty(string path);
    if (!is_file(path)) return 0;
    return c_system($sformatf("test -s %s", path)) != 0;
  endfunction

  function int mkdir(string path);
    return c_system($sformatf("mkdir -p %s", path));
  endfunction

  function int rmdir(string path);
    return c_system($sformatf("rmdir %s", path));
  endfunction

  function void write_text(string path, string content);
    c_write_text(path, content);
  endfunction

  function string read_text(string path);
    int fh;
    string content = "";
    string line;
    int fgets_result;

    clear_error();

    if (!exists(path)) begin
      set_error(-1, $sformatf("File not found: %s", path));
      return "";
    end

    fh = $fopen(path, "r");
    if (fh == 0) begin
      set_error(-2, $sformatf("Cannot open file: %s", path));
      return "";
    end

    while (!$feof(fh)) begin
      fgets_result = $fgets(line, fh);
      if (fgets_result != 0) begin
        content = {content, line};
      end
    end

    $fclose(fh);
    return content;
  endfunction

  function void unlink(string path);
    if (exists(path)) begin
      c_unlink(path);
    end
  endfunction

  function void copy(string src, string dst);
    clear_error();
    if (!exists(src)) begin
      set_error(-1, $sformatf("Source file not found: %s", src));
      return;
    end
    void'(c_system($sformatf("cp %s %s", src, dst)));
  endfunction

  function void rename(string old_path, string new_path);
    void'(c_system($sformatf("mv %s %s", old_path, new_path)));
  endfunction

  function longint size(string path);
    if (!exists(path)) return -1;
    return c_file_size(path);
  endfunction

  function longint modified(string path);
    if (!exists(path)) return -1;
    return c_file_mtime(path);
  endfunction
endpackage
