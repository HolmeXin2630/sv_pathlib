#include <sys/stat.h>
#include <dirent.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

extern "C" {

  int sv_pathlib_exists(const char* path) {
    struct stat buf;
    return stat(path, &buf) == 0;
  }

  int sv_pathlib_is_file(const char* path) {
    struct stat buf;
    if (stat(path, &buf) != 0) return 0;
    return S_ISREG(buf.st_mode);
  }

  int sv_pathlib_is_dir(const char* path) {
    struct stat buf;
    if (stat(path, &buf) != 0) return 0;
    return S_ISDIR(buf.st_mode);
  }

  int sv_pathlib_is_symlink(const char* path) {
    struct stat buf;
    if (lstat(path, &buf) != 0) return 0;
    return S_ISLNK(buf.st_mode);
  }

  int sv_pathlib_is_empty(const char* path) {
    struct stat buf;
    if (stat(path, &buf) != 0) return 0;
    return S_ISREG(buf.st_mode) && buf.st_size == 0;
  }

  int sv_pathlib_mkdir(const char* path) {
    char cmd[1024];
    snprintf(cmd, sizeof(cmd), "mkdir -p \"%s\"", path);
    return system(cmd);
  }

  int sv_pathlib_rmdir(const char* path) {
    return rmdir(path);
  }

  long long sv_pathlib_size(const char* path) {
    struct stat buf;
    if (stat(path, &buf) != 0) return -1;
    return (long long)buf.st_size;
  }

  long long sv_pathlib_modified(const char* path) {
    struct stat buf;
    if (stat(path, &buf) != 0) return -1;
    return (long long)buf.st_mtime;
  }

  void sv_pathlib_copy(const char* src, const char* dst) {
    char cmd[2048];
    snprintf(cmd, sizeof(cmd), "cp \"%s\" \"%s\"", src, dst);
    int ret = system(cmd);
    (void)ret;
  }

  void sv_pathlib_rename(const char* old_path, const char* new_path) {
    rename(old_path, new_path);
  }

  void sv_pathlib_unlink(const char* path) {
    unlink(path);
  }

  int sv_pathlib_symlink(const char* target, const char* linkpath) {
    return symlink(target, linkpath);
  }

  // New functions

  static char readdir_buf[65536];

  int sv_pathlib_readdir(const char* path, char** result) {
    DIR* dir = opendir(path);
    if (!dir) {
      readdir_buf[0] = '\0';
      *result = readdir_buf;
      return -1;
    }

    struct dirent* entry;
    readdir_buf[0] = '\0';
    int pos = 0;
    int first = 1;

    while ((entry = readdir(dir)) != NULL) {
      if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0)
        continue;
      int len = strlen(entry->d_name);
      if (pos + len + 2 >= (int)sizeof(readdir_buf)) break;
      if (!first) readdir_buf[pos++] = '\n';
      memcpy(readdir_buf + pos, entry->d_name, len);
      pos += len;
      first = 0;
    }
    readdir_buf[pos] = '\0';
    closedir(dir);
    *result = readdir_buf;
    return 0;
  }

  int sv_pathlib_stat_full(const char* path, long long* size,
                           long long* mtime, long long* atime,
                           long long* ctime, int* mode) {
    struct stat buf;
    if (stat(path, &buf) != 0) return -1;
    *size = (long long)buf.st_size;
    *mtime = (long long)buf.st_mtime;
    *atime = (long long)buf.st_atime;
    *ctime = (long long)buf.st_ctime;
    *mode = (int)buf.st_mode;
    return 0;
  }

  static char getenv_buf[4096];

  const char* sv_pathlib_getenv(const char* name) {
    const char* val = getenv(name);
    if (!val) {
      getenv_buf[0] = '\0';
      return getenv_buf;
    }
    strncpy(getenv_buf, val, sizeof(getenv_buf) - 1);
    getenv_buf[sizeof(getenv_buf) - 1] = '\0';
    return getenv_buf;
  }

  int sv_pathlib_getcwd(char** result) {
    char buf[4096];
    if (!getcwd(buf, sizeof(buf))) return -1;
    *result = strdup(buf);
    return 0;
  }

  int sv_pathlib_relative_to(const char* path, const char* base, char** result) {
    char rpath[4096], rbase[4096];
    const char *pp, *bp;
    const char *p_next, *b_next;
    char out[4096];
    int up_count = 0;

    if (!realpath(path, rpath) || !realpath(base, rbase))
      return -1;

    // Step 1: find common prefix, advance pp and bp past it
    pp = rpath; bp = rbase;
    while (*pp || *bp) {
      p_next = pp; while (*p_next && *p_next != '/') p_next++;
      b_next = bp; while (*b_next && *b_next != '/') b_next++;

      int plen = (int)(p_next - pp);
      int blen = (int)(b_next - bp);
      if (plen != blen || strncmp(pp, bp, plen) != 0) break;
      pp = *p_next ? p_next + 1 : p_next;
      bp = *b_next ? b_next + 1 : b_next;
    }

    // Step 2: count remaining segments in base path
    if (*bp) {
      up_count = 1;
      const char *p = bp;
      while (*p) { if (*p == '/') up_count++; p++; }
    }

    // Step 3: build result
    out[0] = '\0';
    for (int i = 0; i < up_count; i++) {
      if (i > 0) strcat(out, "/");
      strcat(out, "..");
    }
    if (*pp) {
      if (out[0] != '\0') strcat(out, "/");
      strcat(out, pp);
    }
    if (out[0] == '\0') strcpy(out, ".");

    *result = strdup(out);
    return 0;
  }

}
