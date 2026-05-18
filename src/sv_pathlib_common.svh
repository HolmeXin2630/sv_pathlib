typedef struct {
  longint st_size;
  longint st_mtime;
  longint st_atime;
  longint st_ctime;
  int     st_mode;
} stat_t;

class Path;
  // Path parsing
  static function string name(string path);
    int last_slash = -1;
    for (int i = path.len() - 1; i >= 0; i--) begin
      if (path[i] == "/") begin
        last_slash = i;
        break;
      end
    end
    return path.substr(last_slash + 1, path.len() - 1);
  endfunction

  static function string stem(string path);
    string filename = name(path);
    int last_dot = -1;
    for (int i = filename.len() - 1; i >= 0; i--) begin
      if (filename[i] == ".") begin
        last_dot = i;
        break;
      end
    end
    if (last_dot <= 0) return filename;
    return filename.substr(0, last_dot - 1);
  endfunction

  static function string extension(string path);
    string filename = name(path);
    int last_dot = -1;
    for (int i = filename.len() - 1; i >= 0; i--) begin
      if (filename[i] == ".") begin
        last_dot = i;
        break;
      end
    end
    if (last_dot < 0) return "";
    return filename.substr(last_dot, filename.len() - 1);
  endfunction

  static function string parent(string path);
    int last_slash = -1;
    for (int i = path.len() - 1; i >= 0; i--) begin
      if (path[i] == "/") begin
        last_slash = i;
        break;
      end
    end
    if (last_slash < 0) return "";
    if (last_slash == 0) return "/";
    return path.substr(0, last_slash - 1);
  endfunction

  static function string join_path(string base, string other);
    if (other.len() > 0 && other[0] == "/") return other;
    if (base.len() == 0) return other;
    if (base[base.len() - 1] == "/") return {base, other};
    return {base, "/", other};
  endfunction

  static function string with_name(string path, string new_name);
    string parent_dir = parent(path);
    if (parent_dir == "") return new_name;
    if (parent_dir == "/") return {"/", new_name};
    return {parent_dir, "/", new_name};
  endfunction

  static function string with_suffix(string path, string new_suffix);
    string filename = name(path);
    string parent_dir = parent(path);
    string new_filename;
    int last_dot = -1;

    for (int i = filename.len() - 1; i >= 0; i--) begin
      if (filename[i] == ".") begin
        last_dot = i;
        break;
      end
    end

    if (last_dot > 0)
      new_filename = {filename.substr(0, last_dot - 1), new_suffix};
    else
      new_filename = {filename, new_suffix};

    if (parent_dir == "") return new_filename;
    if (parent_dir == "/") return {"/", new_filename};
    return {parent_dir, "/", new_filename};
  endfunction

  static function bit is_absolute(string path);
    return (path.len() > 0 && path[0] == "/");
  endfunction

  static function string resolve(string path);
    string result = "";
    string component = "";
    int i;
    bit is_abs;
    bit in_component;
    is_abs = is_absolute(path);
    in_component = 0;
    result = is_abs ? "/" : "";
    for (i = is_abs ? 1 : 0; i < path.len(); i++) begin
      if (path[i] == "/") begin
        if (in_component) begin
          if (component == "..") begin
            if (result.len() > 1) begin
              int last_slash = -1;
              int j;
              for (j = result.len() - 2; j >= 0; j--) begin
                if (result[j] == "/") begin
                  last_slash = j;
                  break;
                end
              end
              if (last_slash > 0)
                result = result.substr(0, last_slash - 1);
              else if (last_slash == 0)
                result = "/";
              else
                result = "";
            end else if (result == "/") begin
            end
          end else if (component != ".") begin
            if (result == "/")
              result = {result, component};
            else if (result.len() == 0)
              result = component;
            else
              result = {result, "/", component};
          end
          component = "";
          in_component = 0;
        end
      end else begin
        component = {component, path[i]};
        in_component = 1;
      end
    end
    if (in_component) begin
      if (component == "..") begin
        if (result.len() > 1) begin
          int last_slash = -1;
          int j;
          for (j = result.len() - 2; j >= 0; j--) begin
            if (result[j] == "/") begin
              last_slash = j;
              break;
            end
          end
          if (last_slash > 0)
            result = result.substr(0, last_slash - 1);
          else if (last_slash == 0)
            result = "/";
          else
            result = "";
        end else if (result == "/") begin
        end else if (result.len() == 0) begin
          result = "..";
        end
      end else if (component != ".") begin
        if (result == "/")
          result = {result, component};
        else if (result.len() == 0)
          result = component;
        else
          result = {result, "/", component};
      end
    end
    if (result == "" && !is_abs) result = ".";
    return result;
  endfunction

  static function string absolute(string path);
    if (is_absolute(path)) return resolve(path);
    return resolve(join_path(cwd(), path));
  endfunction

  // File I/O (shared - uses SV built-in file operations)
  static function string read_text(string path);
    int fh;
    string content = "";
    string line;
    int fgets_result;

    if (!exists(path)) begin
      $warning("sv_pathlib: file not found: %s", path);
      return "";
    end

    fh = $fopen(path, "r");
    if (fh == 0) begin
      $warning("sv_pathlib: cannot open file: %s", path);
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

  static function void write_text(string path, string content);
    int fh = $fopen(path, "w");
    if (fh == 0) begin
      $warning("sv_pathlib: cannot open file for writing: %s", path);
      return;
    end
    $fwrite(fh, "%s", content);
    $fclose(fh);
  endfunction
