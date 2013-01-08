#lang racket

(require slideshow/pict
         racket/draw
         (except-in unstable/gui/ppict grid)
         (for-syntax syntax/parse
                     syntax/parse/experimental/template)
         (for-meta 2 syntax/parse)
         (for-meta 2 racket/base))

(provide grid arc path degrees->radians backdrop)

;; grid : nat nat nat [nat] -> pict
;; draw a grid
(define (grid width height step [line-width 1])
  (define vlines
    (apply hc-append
           (cons (- step line-width)
                 (build-list (sub1 (floor (/ width step)))
                             (lambda (_)
                               (vline line-width height))))))
  (define hlines
    (apply vc-append
           (cons (- step line-width)
                 (build-list (sub1 (floor (/ width step)))
                             (lambda (_)
                               (hline width line-width))))))
  vlines
  (cc-superimpose vlines hlines))

;; arc : nat nat real real -> pict
;; draw an arc pict
(define (arc width height start-radians end-radians)
  (dc (λ (dc x y)
        (send dc draw-arc
              x y
              width height
              start-radians end-radians))
      width
      height))

;; degrees->radians : real -> real
(define (degrees->radians r)
  (* r (/ (* 2 pi) 360)))

;; path
;; pict macro for drawing paths
;; e.g.
;; (path 100 200
;;       (move-to 0 0)
;;       (arc 30 30 0 (degrees->radians 30))
;;       (close))
(define-syntax (path stx)
  (define-syntax (define-path-elem stx)
    (syntax-parse stx
      [(_ class-name:id (method:id attr:id (arg:id ...)) ...)
       #'(define-syntax-class class-name
           (pattern ((~literal method) arg ...)
                    #:with attr #'(λ (p) (send p method arg ...))) ...)]))

  (define-path-elem path-elem
    (append expr [path])
    (arc expr [x y w h sr er])
    (close expr [])
    (curve-to expr [x1 y1 x2 y2 x3 y3])
    (ellipse expr [x y w h])
    (move-to expr [x y])
    (line-to expr [x y])
    (lines expr [points])
    (rectangle expr [x y w h])
    (reset expr [])
    (reverse expr [])
    (rotate expr [radians])
    (rounded-rectangle expr [x y w h])
    (scale expr [x y])
    (text-outline expr [f s x y])
    (translate expr [x y]))

  (syntax-parse stx
    [(_ (~optional (~seq #:brush ?brush:expr))
        (~optional (~seq #:pen ?pen:expr))
        ?elem:path-elem ...)
     (template
      (let ()
        (define p (new dc-path%))
        (?elem.expr p) ...
        (define-values (x y w h)
          (send p get-bounding-box))
        (dc (λ (dc dx dy)
              (define old-pen (send dc get-pen))
              (define old-brush (send dc get-brush))
              (?? (send dc set-pen ?pen) (void))
              (?? (send dc set-brush ?brush) (void))
              (send dc draw-path p dx (+ dy h))
              (send dc set-pen old-pen)
              (send dc set-brush old-brush))
            w h)))]))

;; backdrop: pict [#:color color] -> pict
(define (backdrop pict #:color [color "white"])
  (cc-superimpose (colorize (filled-rectangle (pict-width pict)
                                              (pict-height pict))
                            color)
                  pict))