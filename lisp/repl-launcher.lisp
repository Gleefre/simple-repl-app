;; Preloaded libraries, package

(ql:quickload '(:alexandria
                :serapeum))
(ql:quickload '(:simple-repl/server
                :cl-android
                :android-log
                :and-jni))

(defpackage #:simple-repl-app
  (:use #:cl #:sb-alien)
  (:import-from #:sb-debug #:print-backtrace)
  (:import-from #:sb-ext
                #:*init-hooks*
                #:save-lisp-and-die)
  (:local-nicknames (#:alog #:android-log/cffi)
                    (#:j    #:and-jni)
                    (#:jll  #:and-jni/cffi)))

(in-package #:simple-repl-app)

;; Simple REPL server

(defparameter *port* 4017)
(defparameter *simple-repl-thread* nil
  "NIL or thread of the Simple REPL.")

(define-alien-callable simple-repl-running-p sb-alien:int ()
  (alog:write :info "ALIEN" (princ-to-string *simple-repl-thread*))
  (when (and *simple-repl-thread*
             (not (bt:thread-alive-p *simple-repl-thread*)))
    (setf *simple-repl-thread* nil))
  (if *simple-repl-thread* 1 0))

(define-alien-callable launch-simple-repl sb-alien:void ()
  (setf *simple-repl-thread*
        (or *simple-repl-thread*
            (simple-repl/server:run *port*))))

;; On click hook

(defparameter *on-click-hook* nil)

(define-alien-callable on-click sb-alien:void ()
  (mapcar #'funcall *on-click-hook*))

;; Custom debugger hook.

(defun log-backtrace-and-abort (condition &optional hook)
  (declare (ignore hook))
  (alog:write :error "ALIEN" (princ-to-string condition))
  (alog:write :error "ALIEN"
              (with-output-to-string (s)
                (print-backtrace :count 20
                                 :stream s)))
  (invoke-restart 'abort))

;; Moving quicklisp home

(defun move-home (path)
  (let ((asdf-cache-path (format nil "~a/.cache/" path)))
    (setf asdf:*user-cache* asdf-cache-path)
    (asdf:clear-configuration))
  (let ((quicklisp-path (format nil "~a/.quicklisp" path)))
    (setf ql:*quicklisp-home* (format nil "~a/" quicklisp-path))
    (setf ql:*local-project-directories*
          (list (format nil "~a/local-projects/" quicklisp-path)))
    (unless (uiop:directory-exists-p quicklisp-path)
      (ql:setup)))
  :done)

(defun get-app-path ()
  (j:with-env (env)
    (unwind-protect
        (j::jstring-to-string env
          (j:call-java-method env
            ("java/io/File" (j:call-java-method env
                              ("android/content/Context" (j:call-java-method env
                                                           ("gleefre/simple/repl/SimpleREPLActivity")
                                                           "getCurrActivity"
                                                           "android/app/Activity"))
                              "getFilesDir"
                              "java/io/File"))
            "getAbsolutePath"
            :string))
      (jll:exception-clear env))))

;; Initialization of the lisp

(defun on-load ()
  (android-log:init)
  (alog:write :info "ALIEN" "Lisp initialization..")
  (setf *debugger-hook* #'log-backtrace-and-abort)
  (cl-android:init)
  (handler-case (move-home (get-app-path))
    (error (c)
      (alog:write :warn "ALIEN" "Wasn't able to move quicklisp home, error occured:")
      (alog:write :warn "ALIEN" (princ-to-string c)))))

(push (lambda ()
        (push (sb-alien::make-shared-object
               :pathname (pathname "lib.gleefre.wrap.so")
               :namestring "lib.gleefre.wrap.so"
               :handle (sb-alien:get-pointer-from-c)
               :dont-save t)
              sb-alien::*shared-objects*)
        (on-load))
      *init-hooks*)

(save-lisp-and-die "lib.gleefre.core.so"
                   :callable-exports '(simple-repl-running-p launch-simple-repl on-click)
                   :compression t)
