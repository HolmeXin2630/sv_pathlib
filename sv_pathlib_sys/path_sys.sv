/* verilator lint_off IMPLICITSTATIC */
package path_sys;
  import "DPI-C" function int c_system(input string cmd);
  import "DPI-C" function void c_write_text(input string path, input string content);
  import "DPI-C" function void c_unlink(input string path);
  import "DPI-C" function longint c_file_size(input string path);
  import "DPI-C" function longint c_file_mtime(input string path);

  // Error handling
  string lastErrorMsg = "";
  int lastErrorCode = 0;

  function void clearError();
    lastErrorMsg = "";
    lastErrorCode = 0;
  endfunction

  function string getLastError();
    return lastErrorMsg;
  endfunction

  function int getLastErrorCode();
    return lastErrorCode;
  endfunction

  function void setError(int code, string msg);
    lastErrorCode = code;
    lastErrorMsg = msg;
  endfunction

  function bit exists(string path);
    return c_system($sformatf("test -e %s", path)) == 0;
  endfunction

  function bit isFile(string path);
    return c_system($sformatf("test -f %s", path)) == 0;
  endfunction

  function bit isDir(string path);
    return c_system($sformatf("test -d %s", path)) == 0;
  endfunction

  function bit isSymlink(string path);
    return c_system($sformatf("test -L %s", path)) == 0;
  endfunction

  function bit isEmpty(string path);
    if (!isFile(path)) return 0;
    return c_system($sformatf("test -s %s", path)) != 0;
  endfunction

  function int mkdir(string path);
    return c_system($sformatf("mkdir -p %s", path));
  endfunction

  function int rmdir(string path);
    return c_system($sformatf("rmdir %s", path));
  endfunction

  function void writeText(string path, string content);
    c_write_text(path, content);
  endfunction

  function string readText(string path);
    int fh;
    string content = "";
    string line;
    int fgetsResult;

    clearError();

    if (!exists(path)) begin
      setError(-1, $sformatf("File not found: %s", path));
      return "";
    end

    fh = $fopen(path, "r");
    if (fh == 0) begin
      setError(-2, $sformatf("Cannot open file: %s", path));
      return "";
    end

    while (!$feof(fh)) begin
      fgetsResult = $fgets(line, fh);
      if (fgetsResult != 0) begin
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
    clearError();
    if (!exists(src)) begin
      setError(-1, $sformatf("Source file not found: %s", src));
      return;
    end
    void'(c_system($sformatf("cp %s %s", src, dst)));
  endfunction

  function void rename(string oldPath, string newPath);
    void'(c_system($sformatf("mv %s %s", oldPath, newPath)));
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
