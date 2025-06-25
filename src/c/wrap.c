#include <jni.h>
#include <string.h>
#include <dlfcn.h>
#include <stdio.h>
#include <unistd.h>
#include <pthread.h>
#include <android/log.h>
#include <fenv.h>
#include <signal.h>

#define LOG_TAG   "ALIEN/GLEEFRE/C"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)

extern int initialize_lisp(int argc, char **argv);
extern void pass_pointer_to_lisp(void* pointer);

__attribute__((visibility("default"))) void (*launch_simple_repl)(void);
__attribute__((visibility("default"))) int (*simple_repl_running_p)(void);
__attribute__((visibility("default"))) void (*on_click)(void);
__attribute__((visibility("default"))) int (*lisp_init)(void);

static int initialized = 0;

static int redirect_pipe[2];

void* redirect_worker(void* arg) {
    char buf[1024];
    ssize_t len;
    LOGI("Worker thread: entering the redirect loop");
    while ((len = read(redirect_pipe[0], buf, sizeof buf - 1)) > 0) {
        if (buf[len - 1] == '\n') --len;  // ignore trailing return if exists
        buf[len] = 0;  // add null-terminator
        __android_log_write(ANDROID_LOG_DEBUG, "ALIEN/GLEEFRE/C/REDIRECT", buf);
    }
    LOGI("Worker thread: exiting the redirect loop");
    return 0;
}

int redirect_stdout_stderr() {
  LOGI("Redirecting stdout/stderr to logcat");

  setvbuf(stdout, NULL, _IOLBF, 0);
  setvbuf(stderr, NULL, _IONBF, 0);
  LOGI("Changed buffering settings on stdout/stderr");

  pipe(redirect_pipe);
  LOGI("Created a pipe");

  dup2(redirect_pipe[1], 1);
  dup2(redirect_pipe[1], 2);
  LOGI("Redirected 1 & 2 to the input part of the pipe");

  pthread_t redirect_thread;
  if (pthread_create(&redirect_thread, NULL, redirect_worker, NULL) == -1) {
      LOGI("Failed to spawn a pipe->logcat thread");
      return -1;
  }
  LOGI("Spawned a pipe->logcat thread");

  pthread_detach(redirect_thread);
  LOGI("Detached the pipe->logcat thread");
  return 0;
}

struct my_siginfo {
    int signum;
    char *name;
};

const struct my_siginfo siglist[] = {
    {SIGHUP,    "SIGHUP"},
    {SIGINT,    "SIGINT"},
    {SIGQUIT,   "SIGQUIT"},
    {SIGILL,    "SIGILL"},
    {SIGTRAP,   "SIGTRAP"},
    {SIGABRT,   "SIGABRT"},
    {SIGBUS,    "SIGBUS"},
    {SIGFPE,    "SIGFPE"},
    {SIGKILL,   "SIGKILL"},
    {SIGUSR1,   "SIGUSR1"},
    {SIGSEGV,   "SIGSEGV"},
    {SIGUSR2,   "SIGUSR2"},
    {SIGPIPE,   "SIGPIPE"},
    {SIGALRM,   "SIGALRM"},
    {SIGTERM,   "SIGTERM"},
    {SIGSTKFLT, "SIGSTKFLT"},
    {SIGCHLD,   "SIGCHLD"},
    {SIGCONT,   "SIGCONT"},
    {SIGSTOP,   "SIGSTOP"},
    {SIGTSTP,   "SIGTSTP"},
    {SIGTTIN,   "SIGTTIN"},
    {SIGTTOU,   "SIGTTOU"},
    {SIGURG,    "SIGURG"},
    {SIGXCPU,   "SIGXCPU"},
    {SIGXFSZ,   "SIGXFSZ"},
    {SIGVTALRM, "SIGVTALRM"},
    {SIGPROF,   "SIGPROF"},
    {SIGWINCH,  "SIGWINCH"},
    {SIGIO,     "SIGIO"},
    {SIGPWR,    "SIGPWR"},
    {SIGSYS,    "SIGSYS"},
};

#define SIGNUM 31

void log_signal_handlers() {
    sigset_t set;
    struct sigaction action;

    // current thread's blocked signal mask
    sigemptyset(&set);
    sigprocmask(0, NULL, &set);

    LOGI("Signal handlers:");
    for (int i = 0; i < SIGNUM; ++i) {
        sigaction(siglist[i].signum, NULL, &action);
        void* pointer = action.sa_flags & SA_SIGINFO ? (void*) action.sa_handler : (void*) action.sa_sigaction;
        int siginfo_p = action.sa_flags & SA_SIGINFO ? 1 : 0;
        int default_p = pointer == SIG_DFL ? 1 : 0;
        int ignore_p = pointer == SIG_IGN ? 1 : 0;
        LOGI("  %9s: blocked_p=%d; action: siginfo_p=%d, default_p=%d, ignore_p=%d, pointer=%p",
             siglist[i].name,
             sigismember(&set, siglist[i].signum),
             siginfo_p, default_p, ignore_p, pointer);
    }
}

int init(char* core) {
  LOGI("Lisp init");
  char *init_args[] = {"", "--core", core, "--disable-ldb", "--disable-debugger"};
  void* self_handle = dlopen("lib.gleefre.wrap.so", RTLD_NOLOAD | RTLD_GLOBAL);
  if (self_handle == NULL) return -2;
  pass_pointer_to_lisp(self_handle);
  if (initialize_lisp(5, init_args) != 0) return -1;
  if (lisp_init() != 0) return -3;
  return 0;
}

JNIEXPORT void JNICALL
Java_gleefre_simple_repl_SimpleREPLActivity_initLisp(JNIEnv *env, jobject thiz, jstring path) {
  LOGI("initLisp: fegetexcept() = %d", fegetexcept());
  log_signal_handlers();
  if (initialized != 0) {
    LOGW("Tried to initialize lisp, but it was already initialized!");
    return;
  }
  LOGI("Redirect status: %d", redirect_stdout_stderr());
  char* core_filename = strdup((*env)->GetStringUTFChars(env, path, NULL));
  LOGI("Init status: %d", init(core_filename));
  initialized = 1;
  LOGI("initLisp: fegetexcept() = %d", fegetexcept());
  log_signal_handlers();
}

JNIEXPORT void JNICALL
Java_gleefre_simple_repl_SimpleREPLActivity_onClickLisp(JNIEnv *env, jobject thiz) {
  LOGI("onClickLisp: fegetexcept() = %d", fegetexcept());
  log_signal_handlers();
  LOGI("Clicked, calling into lisp..");
  on_click();
  LOGI("onClickLisp: fegetexcept() = %d", fegetexcept());
  log_signal_handlers();
}

JNIEXPORT void JNICALL
Java_gleefre_simple_repl_SimpleREPLActivity_launchSimpleREPL(JNIEnv *env, jobject thiz) {
  LOGI("launchSimpleREPL: fegetexcept() = %d", fegetexcept());
  log_signal_handlers();
  LOGI("Calling into lisp to launch simple REPL");
  launch_simple_repl();
  LOGI("launchSimpleREPL: fegetexcept() = %d", fegetexcept());
  log_signal_handlers();
}

JNIEXPORT jboolean JNICALL
Java_gleefre_simple_repl_SimpleREPLActivity_simpleREPLRunning(JNIEnv *env, jobject thiz) {
  LOGI("simpleREPLRunning: fegetexcept() = %d", fegetexcept());
  log_signal_handlers();
  LOGI("Calling into lisp to check if simple REPL is running");
  if (simple_repl_running_p()) {
    LOGI("It is running.");
    LOGI("simpleREPLRunning: fegetexcept() = %d", fegetexcept());
    log_signal_handlers();
    return JNI_TRUE;
  } else {
    LOGI("It is not running.");
    LOGI("simpleREPLRunning: fegetexcept() = %d", fegetexcept());
    log_signal_handlers();
    return JNI_FALSE;
  }
}
