class Path;
  protected string path_str;

  function new(string path = "");
    this.path_str = path;
  endfunction

  virtual function string str();
    return this.path_str;
  endfunction

  virtual function string to_string();
    return this.path_str;
  endfunction

  // Static methods for path parsing
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

  // Static methods for path operations
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
endclass
