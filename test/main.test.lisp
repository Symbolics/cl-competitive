(eval-when (:compile-toplevel :load-toplevel :execute)
  (load "test-util")
  (load "../ext-gcd.lisp")
  (load "../bounded-partition-number.lisp")
  (load "../bisect.lisp")
  (load "../bipartite-matching.lisp")
  (load "../buffered-read-line.lisp")
  (load "../read-line-into.lisp")
  (load "../log-ceil.lisp")
  (load "../ford-fulkerson.lisp"))

(use-package :test-util)

;;;
;;; ext-gcd.lisp
;;;

(with-test (:name mod-log)
  (dotimes (i 100)
    (let ((a (- (random 20) 10))
          (b (- (random 20) 10)))
      (multiple-value-bind (x y) (ext-gcd a b)
        (assert (= (+ (* a x) (* b y)) (gcd a b))))))
  (assert (= 8 (mod-log 6 4 44)))
  (assert (= 8 (mod-log -38 -40 44)))
  (assert (null (mod-log 6 2 44)))
  (assert (= 2 (mod-log 8 4 12)))
  (assert (= 4 (mod-log 3 13 17)))
  (assert (= 1 (mod-log 12 0 4)))
  (assert (= 2 (mod-log 12 0 8)))
  (assert (null (mod-log 12 1 8)))
  (assert (= 1 (mod-log 0 0 100))))

(with-test (:name mod-inverse)
  (dotimes (i 1000)
    (let ((a (random 100))
          (m (+ 2 (random 100))))
      (assert (or (/= 1 (gcd a m))
                  (= 1 (mod (* a (mod-inverse a m)) m)))))))

(with-test (:name solve-bezout)
  (assert (= (calc-min-factor 8 3) -2))
  (assert (= (calc-min-factor -8 3) 3))
  (assert (= (calc-min-factor 8 -3) 2))
  (assert (= (calc-min-factor -8 -3) -3))
  (assert (= (calc-max-factor 8 3) -3))
  (assert (= (calc-max-factor -8 3) 2))
  (assert (= (calc-max-factor 8 -3) 3))
  (assert (= (calc-max-factor -8 -3) -2)))

;;;
;;; bounded-partition-number.lisp
;;;

(with-test (:name make-bpartition)
  (let ((table (make-bpartition 1 0 100000)))
    (assert (= 1 (aref table 0 0)))
    (assert (equal '(1 1) (array-dimensions table))))
  (let ((table (make-bpartition 361 25 100000)))
    (assert (= 74501 (aref table 360 25)))
    (assert (= (aref table 3 3) (aref table 3 4) (aref table 3 5)))
    (assert (= 0 (aref table 3 0)))
    (assert (= 1 (aref table 0 0)))
    (assert (= 1 (aref table 0 1)))))

;;;
;;; bisect.lisp
;;;

(with-test (:name bisect-left)
  (assert (= 0 (bisect-left #(1 8) -3)))
  (assert (= 0 (bisect-left #(1 8) 1)))
  (assert (= 1 (bisect-left #(1 8) 4)))
  (assert (= 1 (bisect-left #(1 8) 8)))
  (assert (= 2 (bisect-left #(1 8) 9)))
  (assert (= 3 (bisect-left #(1 4 5 7 7 7 7 7 7 8) 7)))
  (assert (= 3 (bisect-left #(1 4 4 7 7 7 7 7 8) 6)))
  (assert (= 1 (bisect-left #(#\a #\c #\c #\d) #\b :predicate #'char<)))
  (assert (= 4 (bisect-left #(nil 1 4 4 7 7 nil nil) 6 :start 1 :end 4))))

(with-test (:name bisect-right)
  (assert (= 0 (bisect-right #(1) 0)))
  (assert (= 1 (bisect-right #(1) 1)))
  (assert (= 1 (bisect-right #(1) 2)))
  (assert (= 0 (bisect-right #(1 8) 0)))
  (assert (= 2 (bisect-right #(1 8) 8)))
  (assert (= 1 (bisect-right #(1 8) 4)))
  (assert (= 1 (bisect-right #(1 8) 1)))
  (assert (= 2 (bisect-right #(1 8) 9)))
  (assert (= 7 (bisect-right #(1 4 5 7 7 7 7 8) 7)))
  (assert (= 3 (bisect-right #(1 4 4 7 7 7 7 7 8) 6)))
  (assert (= 3 (bisect-right #(10 9 9 7 7 7 7 7 4) 9 :predicate #'>)))
  (assert (= 3 (bisect-right #(#\a #\c #\c #\d) #\c :predicate #'char<)))
  (assert (= 4 (bisect-right #(nil 1 4 4 4 4 7 7 nil nil) 4 :start 1 :end 4))))

;;;
;;; bipartite-matching.lisp
;;;


(with-test (:name find-matcning)
  (let* ((graph (make-array 9
                            :element-type 'list
                            :initial-contents '((6) (5 6 7 8) (6) (6) (5) (1 4) (0 1 2 3) (1) (1))))
         (matching (find-matching graph)))
    (loop for i below 9
          do (assert (or (= (aref matching i) -1)
                         (= i (aref matching (aref matching i))))))
    (assert (= 6 (count -1 matching :test-not #'=)))))

;;;
;;; buffered-read-line.lisp
;;; read-line-into.lisp
;;;

;; acknowledge: https://stackoverflow.com/questions/41378669/how-to-get-a-stream-from-a-bit-vector-in-common-lisp
(defclass octet-input-stream (fundamental-binary-input-stream)
  ((data :initarg :data :type (vector (unsigned-byte 8)))
   (position :initform 0)))

(defmethod stream-element-type ((stream octet-input-stream))
  '(unsigned-byte 8))

(defmethod stream-read-byte ((stream octet-input-stream))
  (with-slots (data position) stream
    (if (< position (length data))
        (prog1 (aref data position)
          (incf position))
        :eof)))

(defun make-octet-input-stream (data)
  (etypecase data
    (string (let ((octets (make-array (length data) :element-type '(unsigned-byte 8))))
              (dotimes (i (length data))
                (setf (aref octets i) (char-code (aref data i))))
              (make-instance 'octet-input-stream :data octets)))
    (sequence (make-instance 'octet-input-stream
                              :data (coerce data '(simple-array (unsigned-byte 8) (*)))))))

(with-test (:name buffered-read-line)
  (let ((*standard-input* (make-octet-input-stream "foo")))
    (equalp "foo  " (buffered-read-line 5))
    (let ((*standard-input* (make-octet-input-stream "foo")))
      (equalp "foo" (buffered-read-line 3)))))

(with-test (:name read-line-into)
  (let ((buf (make-string 5 :element-type 'base-char))
        (*standard-input* (make-octet-input-stream "foo")))
    (equalp "foo  " (read-line-into buf))
    (let ((buf (make-string 3))
          (*standard-input* (make-octet-input-stream "foo")))
      (equalp "foo" (read-line-into buf)))))

;;;
;;; log-ceil.lisp
;;;

(with-test (:name log2-ceil)
  (assert (= 0 (log2-ceil 0)))
  (assert (= 0 (log2-ceil 1)))
  (assert (= 1 (log2-ceil 1.5d0)))
  (assert (= 1 (log2-ceil 2)))
  (assert (= 2 (log2-ceil 2.1)))
  (assert (= 2 (log2-ceil 5/2)))
  (assert (= 2 (log2-ceil 4))))

(with-test (:name log-ceil)
  (assert (= 0 (log-ceil 0 2)))
  (assert (= 0 (log-ceil 1 2)))
  (assert (= 1 (log-ceil 1.5d0 2)))
  (assert (= 1 (log-ceil 2 2)))
  (assert (= 2 (log-ceil 2.1 2)))
  (assert (= 2 (log-ceil 5/2 2)))
  (assert (= 2 (log-ceil 4 2)))
  (signals type-error (log-ceil 4 2.1))
  (assert (= 0 (log-ceil 0 3)))
  (assert (= 0 (log-ceil 1 3)))
  (assert (= 1 (log-ceil 1.5d0 3)))
  (assert (= 1 (log-ceil 3 3)))
  (assert (= 2 (log-ceil 3.1 3)))
  (assert (= 2 (log-ceil 7/2 3)))
  (assert (= 3 (log-ceil 27 3))))
