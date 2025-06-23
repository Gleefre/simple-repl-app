;; Preloaded libraries, package

(ql:quickload '(:alexandria
                :serapeum))
(ql:quickload '(:simple-repl/server
                :cl-android
                :android-log
                :and-jni))
(ql:quickload '(:bordeaux-threads))

(defpackage #:simple-repl-app
  (:use #:cl #:sb-alien)
  (:import-from #:sb-debug #:print-backtrace)
  (:import-from #:sb-ext
                #:*init-hooks*
                #:save-lisp-and-die)
  (:local-nicknames (#:alog #:android-log/cffi)
                    (#:j    #:and-jni)
                    (#:jll  #:and-jni/cffi))
  (:export #:*on-click-hooks*
           #:*port*
           #:*simple-repl-thread*
           #:move-home
           #:get-app-path
           #:log-backtrace))

(in-package #:simple-repl-app)

;; Logging

(defparameter *log-tag* "ALIEN/GLEEFRE/LISP")

(defun alog (level fmt &rest args)
  (alog:write level *log-tag* (format nil fmt args)))

(defun log-print (obj &optional (fmt "~S") (level :info))
  (alog level fmt obj)
  obj)

;; Custom debugger hook, handler-bind hook

(defun log-backtrace (condition &optional hook)
  (declare (ignore hook))
  (alog :error "~A" condition)
  (alog :error "~A" (with-output-to-string (s)
                      (print-backtrace :count 20
                                       :stream s))))

(defun log-error (condition)
  (log-backtrace condition)
  (when (boundp 'j:*pending-exception*)
    (alog :error "Java error: ~A" j:*pending-exception*)
    (j:with-env (env) (jll:exception-describe env))))

;; checking for java errors

(defmacro checking (expr &aux ($env (gensym "env")))
  `(j:with-env (,$env)
     (multiple-value-prog1 ,expr
       (handler-bind ((error #'log-error))
         (j:check-for-exception ,$env)))))

;; Simple REPL server

(defparameter *port* 4017)
(defparameter *simple-repl-thread* nil
  "NIL or thread of the Simple REPL.")

(define-alien-callable simple-repl-running-p sb-alien:int ()
  (alog :info "simple-repl-running-p entry")
  (when (and *simple-repl-thread*
             (not (bt:thread-alive-p *simple-repl-thread*)))
    (setf *simple-repl-thread* nil))
  (if *simple-repl-thread* 1 0))

(define-alien-callable launch-simple-repl sb-alien:void ()
  (alog :info "launch-simple-repl entry")
  (setf *simple-repl-thread*
        (or *simple-repl-thread*
            (simple-repl/server:run *port*))))

;; On click hook

(defparameter *on-click-hooks* nil)

(define-alien-callable on-click sb-alien:void ()
  (alog :info "on-click entry")
  (alog :info "current thread: ~A, *on-click-hooks: ~A" (bt:current-thread) *on-click-hooks*)
  (mapcar #'funcall *on-click-hooks*))

;; Moving quicklisp home

(defun move-home (path)
  ;; swank -- temp files
  #+nil
  (let ((swank-compile-path (format nil "~a/.swank/" path)))
    (ensure-directories-exist swank-compile-path)
    (defun swank/sbcl::temp-file-name ()
      (swank/sbcl::tempnam swank-compile-path "slime")))
  ;; asdf cache
  (let ((asdf-cache-path (format nil "~a/.cache/" path)))
    (setf asdf:*user-cache* asdf-cache-path)
    (asdf:clear-configuration))
  ;; quicklisp
  (let ((quicklisp-path (format nil "~a/.quicklisp" path)))
    (setf ql:*quicklisp-home* (format nil "~a/" quicklisp-path))
    (setf ql:*local-project-directories* (list (format nil "~a/local-projects/" quicklisp-path)))
    (unless (uiop:directory-exists-p quicklisp-path)
      (ql:setup)))
  :done)

(defun get-app-path ()
  (alog :info "get-app-path starting")
  (log-print
   (let* ((activity
            (log-print
             (checking
              (j:jcall (:class "android/app/Activity")
                       ("gleefre/simple/repl/SimpleREPLActivity" "getCurrActivity")
                       :static))))
          (file
            (log-print
             (checking
              (j:jcall (:class "java/io/File")
                       ("android/content/Context" "getFilesDir")
                       activity))))
          (path
            (log-print
             (checking
              (j:jcall :string
                       ("java/io/File" "getAbsolutePath")
                       file)))))
     path)
   "App path found: ~S"))

;; Initialization of the lisp

(defun on-load ()
  (android-log:init)
  (alog:write :info *log-tag* "Lisp initialization..")
  (setf *debugger-hook* #'log-backtrace)
  (j:with-env (env)
    (log-print (jll:ensure-local-capacity env 64) "Ensuring local capacity... (~A)")
    (handler-bind ((error #'log-error))
      (move-home (get-app-path))))
  (cl-android:init))

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
