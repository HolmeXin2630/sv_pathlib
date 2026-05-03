class Path;
  protected string pathString;

  function new(string path = "");
    this.pathString = path;
  endfunction

  virtual function string str();
    return this.pathString;
  endfunction

  // Static methods for path parsing
  static function string name(string path);
    int lastSlash = -1;
    for (int i = path.len() - 1; i >= 0; i--) begin
      if (path[i] == "/") begin
        lastSlash = i;
        break;
      end
    end
    return path.substr(lastSlash + 1, path.len() - 1);
  endfunction

  static function string stem(string path);
    string filename = name(path);
    int lastDot = -1;
    for (int i = filename.len() - 1; i >= 0; i--) begin
      if (filename[i] == ".") begin
        lastDot = i;
        break;
      end
    end
    if (lastDot <= 0) return filename;
    return filename.substr(0, lastDot - 1);
  endfunction

  static function string extension(string path);
    string filename = name(path);
    int lastDot = -1;
    for (int i = filename.len() - 1; i >= 0; i--) begin
      if (filename[i] == ".") begin
        lastDot = i;
        break;
      end
    end
    if (lastDot < 0) return "";
    return filename.substr(lastDot, filename.len() - 1);
  endfunction

  static function string parent(string path);
    int lastSlash = -1;
    for (int i = path.len() - 1; i >= 0; i--) begin
      if (path[i] == "/") begin
        lastSlash = i;
        break;
      end
    end
    if (lastSlash < 0) return "";
    if (lastSlash == 0) return "/";
    return path.substr(0, lastSlash - 1);
  endfunction

  // Static methods for path operations
  static function string joinPath(string base, string other);
    if (other.len() > 0 && other[0] == "/") return other;
    if (base.len() == 0) return other;
    if (base[base.len() - 1] == "/") return {base, other};
    return {base, "/", other};
  endfunction

  static function string withName(string path, string newName);
    string parentDir = parent(path);
    if (parentDir == "") return newName;
    if (parentDir == "/") return {"/", newName};
    return {parentDir, "/", newName};
  endfunction

  static function string withSuffix(string path, string newSuffix);
    string filename = name(path);
    string parentDir = parent(path);
    string newFilename;
    int lastDot = -1;

    for (int i = filename.len() - 1; i >= 0; i--) begin
      if (filename[i] == ".") begin
        lastDot = i;
        break;
      end
    end

    if (lastDot > 0)
      newFilename = {filename.substr(0, lastDot - 1), newSuffix};
    else
      newFilename = {filename, newSuffix};

    if (parentDir == "") return newFilename;
    if (parentDir == "/") return {"/", newFilename};
    return {parentDir, "/", newFilename};
  endfunction

  static function bit isAbsolute(string path);
    return (path.len() > 0 && path[0] == "/");
  endfunction
endclass
