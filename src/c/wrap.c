#include <jni.h>
#include <string.h>
#include <dlfcn.h>
#include <android/log.h>

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

int init(char* core) {
  LOGI("Lisp init");
  char *init_args[] = {"", "--core", core};
  void* self_handle = dlopen("lib.gleefre.wrap.so", RTLD_NOLOAD | RTLD_GLOBAL);
  if (self_handle == NULL) return -2;
  pass_pointer_to_lisp(self_handle);
  if (initialize_lisp(3, init_args) != 0) return -1;
  if (lisp_init() != 0) return -3;
  return 0;
}

JNIEXPORT void JNICALL
Java_gleefre_simple_repl_SimpleREPLActivity_initLisp(JNIEnv *env, jobject thiz, jstring path) {
  if (initialized != 0) {
    LOGW("Tried to initialize lisp, but it was already initialized!");
    return;
  }
  char* core_filename = strdup((*env)->GetStringUTFChars(env, path, NULL));
  LOGI("Init status: %d", init(core_filename));
  initialized = 1;
}

JNIEXPORT void JNICALL
Java_gleefre_simple_repl_SimpleREPLActivity_onClickLisp(JNIEnv *env, jobject thiz) {
  LOGI("Clicked, calling into lisp..");
  on_click();
}

JNIEXPORT void JNICALL
Java_gleefre_simple_repl_SimpleREPLActivity_launchSimpleREPL(JNIEnv *env, jobject thiz) {
  LOGI("Calling into lisp to launch simple REPL");
  launch_simple_repl();
}

JNIEXPORT jboolean JNICALL
Java_gleefre_simple_repl_SimpleREPLActivity_simpleREPLRunning(JNIEnv *env, jobject thiz) {
  if (simple_repl_running_p()) {
    return JNI_TRUE;
  } else {
    return JNI_FALSE;
  }
}
