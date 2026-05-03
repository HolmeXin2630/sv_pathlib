#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>

#ifdef __cplusplus
extern "C" {
#endif

int c_system(const char* cmd) {
    return system(cmd);
}

void c_write_text(const char* path, const char* content) {
    FILE* fh = fopen(path, "w");
    if (fh) {
        fputs(content, fh);
        fclose(fh);
    }
}

char* c_read_text(const char* path) {
    FILE* fh;
    char* buf;
    long len;
    size_t nread;

    fh = fopen(path, "r");
    if (!fh) {
        buf = (char*)malloc(1);
        buf[0] = '\0';
        return buf;
    }

    fseek(fh, 0, SEEK_END);
    len = ftell(fh);
    fseek(fh, 0, SEEK_SET);

    buf = (char*)malloc(len + 1);
    if (buf) {
        nread = fread(buf, 1, len, fh);
        buf[nread] = '\0';
    }

    fclose(fh);
    return buf ? buf : strdup("");
}

void c_unlink(const char* path) {
    remove(path);
}

long c_file_size(const char* path) {
    struct stat st;
    if (stat(path, &st) == 0) return (long)st.st_size;
    return -1;
}

long c_file_mtime(const char* path) {
    struct stat st;
    if (stat(path, &st) == 0) return (long)st.st_mtime;
    return -1;
}

#ifdef __cplusplus
}
#endif
