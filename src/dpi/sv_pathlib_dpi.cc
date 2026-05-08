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

  int sv_pathlib_readdir(const char* path, char** result) {
    DIR* dir = opendir(path);
    if (!dir) {
      *result = strdup("");
      return -1;
    }

    // First pass: calculate total size
    struct dirent* entry;
    int total_len = 0;
    int count = 0;
    while ((entry = readdir(dir)) != NULL) {
      if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0)
        continue;
      total_len += strlen(entry->d_name) + 1; // +1 for \n
      count++;
    }
    rewinddir(dir);

    if (count == 0) {
      *result = strdup("");
      closedir(dir);
      return 0;
    }

    // Second pass: build result string
    *result = (char*)malloc(total_len + 1);
    if (!*result) {
      closedir(dir);
      return -1;
    }
    (*result)[0] = '\0';

    while ((entry = readdir(dir)) != NULL) {
      if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0)
        continue;
      strcat(*result, entry->d_name);
      strcat(*result, "\n");
    }
    closedir(dir);
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

}
