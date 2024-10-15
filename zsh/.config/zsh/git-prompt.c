#include <ctype.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#if __linux__
#include <sys/wait.h>
#endif

#ifdef DEBUG
#define check(CONDITION)                                                       \
  if (CONDITION) {                                                             \
    fprintf(stderr, "error: %s: %d: %s\n", __FILE__, __LINE__, #CONDITION);    \
    exit(0);                                                                   \
  }
#else
#define check(CONDITION)                                                       \
  if (CONDITION) {                                                             \
    exit(0);                                                                   \
  }
#endif

typedef struct process {
  pid_t pid;
  FILE *out;
} process_t;

process_t process_open(char *command) {
  int fds[2];
  check(pipe(fds));
  int pid = fork();
  check(pid == -1);
  if (pid == 0) { // child process
    close(fds[0]);
    dup2(fds[1], STDOUT_FILENO);
    dup2(STDOUT_FILENO, STDERR_FILENO);
    char *argv[] = {"sh", "-c", command, NULL};
    exit(execvp(argv[0], argv));
  } else { // parent process
    close(fds[1]);
    process_t process = {pid, fdopen(fds[0], "rb")};
    return process;
  }
}

int process_close(process_t process) {
  fclose(process.out);
  int status;
  check(process.pid != waitpid(process.pid, &status, 0));
  if (WIFEXITED(status)) {
    return WEXITSTATUS(status);
  }
  return 0;
}

char *trim(char *str) {
  char *end;
  while (isspace((unsigned char)*str)) {
    str++;
  }
  if (*str == 0) {
    return str;
  }
  end = str + strlen(str) - 1;
  while (end > str && isspace((unsigned char)*end)) {
    end--;
  }
  end[1] = '\0';
  return str;
}

char *append(char *buffer, int count, ...) {
  va_list list;
  va_start(list, count);
  for (int i = 0; i < count; i++) {
    strcat(buffer, va_arg(list, char *));
  }
  va_end(list);
  return buffer;
}

char *inttostr(char *buffer, int value) {
  sprintf(buffer, "%d", value);
  return buffer;
}

int main() {
  // get the current branch name
  process_t process = process_open("git symbolic-ref --short HEAD");
  char branch_buf[256] = {};
  fread(branch_buf, 1, sizeof(branch_buf), process.out);
  if (process_close(process)) {
    // current HEAD is not a symbolic ref
    process = process_open("git rev-parse --abbrev-ref HEAD");
    memset(branch_buf, 0, sizeof(branch_buf));
    fread(branch_buf, 1, sizeof(branch_buf), process.out);
    check(process_close(process));
    if (strcmp("HEAD", trim(branch_buf)) == 0) {
      // get the commit hash
      process = process_open("git rev-parse --short HEAD");
      memset(branch_buf, 0, sizeof(branch_buf));
      fread(branch_buf, 1, sizeof(branch_buf), process.out);
      check(process_close(process));
    }
  }
  char *branch = trim(branch_buf);
  char prompt[1024] = {};
  append(prompt, 3, " %{%F{66}%}", branch, "%{%f%}");

  // get the upstream remote if one exists
  char command[1024] = {};
  append(command, 3, "git config branch.", branch, ".remote");
  process = process_open(command);
  char remote_buf[256] = {};
  fread(remote_buf, 1, sizeof(remote_buf), process.out);
  if (process_close(process) == 0) {
    char *remote = trim(remote_buf);
    // get the number of commits ahead of the remote
    memset(command, 0, sizeof(command));
    process = process_open(append(command, 5,
                                  "git rev-list --right-only refs/remotes/",
                                  remote, "/", branch, "...HEAD --count"));
    char count[32] = {};
    fread(count, 1, sizeof(count), process.out);
    if (process_close(process) == 0 && strcmp("0", trim(count))) {
      append(prompt, 2, "↑", trim(count));
    }

    // get the number of commits behind the remote
    memset(command, 0, sizeof(command));
    process = process_open(append(command, 5,
                                  "git rev-list --left-only refs/remotes/",
                                  remote, "/", branch, "...HEAD --count"));
    memset(count, 0, sizeof(count));
    fread(count, 1, sizeof(count), process.out);
    if (process_close(process) == 0 && strcmp("0", trim(count))) {
      append(prompt, 2, "↓", trim(count));
    }
  }
  append(prompt, 1, " ");

  // get the status and parse it
  process = process_open("git status --porcelain");
  char status[2048];
  int indexed = 0, modified = 0, deleted = 0, untracked = 0, unmerged = 0;
  while (NULL != fgets(status, sizeof(status) - 1, process.out)) {
    char X = status[0];
    char Y = status[1];

    if (X == '?' && Y == '?') {
      ++untracked;
    } else if ((X == 'A' && (Y == 'A' || Y == 'U')) ||
               (X == 'D' && (Y == 'D' || Y == 'U')) ||
               (X == 'U' && (Y == 'A' || Y == 'D' || Y == 'D' || Y == 'U'))) {
      ++unmerged;
    } else {
      switch (X) {
      case ' ':
        switch (Y) {
          case 'M': ++modified; break;
          case 'D': ++deleted;  break;
        } break;
      case 'D': ++indexed;
        switch (Y) {
          case ' ': break;
          case 'M': ++modified; break;
        } break;
      case 'M': case 'A': case 'R': case 'C': ++indexed;
        switch (Y) {
          case ' ': break;
          case 'M': ++modified; break;
          case 'D': ++deleted;  break;
        } break;
      }
    }
  }
  check(process_close(process));

  if (indexed || modified || deleted || unmerged || untracked) { // modified
    char int_buf[32];
    if (indexed) {
      append(prompt, 3, "%{%F{2}%}*", inttostr(int_buf, indexed), "%{%f%}");
    }
    if (modified) {
      append(prompt, 3, "%{%F{1}%}+", inttostr(int_buf, modified), "%{%f%}");
    }
    if (deleted) {
      append(prompt, 3, "%{%F{1}%}-", inttostr(int_buf, deleted), "%{%f%}");
    }
    if (unmerged) {
      append(prompt, 3, "%{%B%F{1}%}×", inttostr(int_buf, unmerged), "%{%f%b%}");
    }
    if (untracked) {
      append(prompt, 1, "%{%F{1}%}…%{%f%}");
    }
  } else { // clean
    append(prompt, 1, "%{%B%F{2}%}✓%{%f%b%}");
  }

  // print the prompt
  puts(prompt);
  return 0;
}
