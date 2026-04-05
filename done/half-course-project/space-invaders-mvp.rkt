;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-abbr-reader.ss" "lang")((modname space-invaders-mvp) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
(require 2htdp/universe)
(require 2htdp/image)

;; Space Invaders
;;  - V0 -> with only the tank functions
;;  - V1 -> tank and missiles functions
;;  - V2 -> lots of other versions before re arranging all of it
;;  - V3 -> done big bang and a lot of other things the only thing to do is to make missiles hit invaders
;;  - V4 -> done mvp thanks Allah

;; may Allah give you strength you brother
;; first day -> 4.5 to 5 hours
;; second day -> 3 to 4.5 hours
;; third day -> 2 hours


;; In this final project, you will complete the design of the classic arcade game Space Invaders.
;; If you've never played it before, you can get an idea of how it works here.
;;
;; There are many different versions of Space Invaders. For this project,
;; your Space Invaders game should have the following behaviour:
;;
;;     The tank should move right and left at the bottom of the screen when you press the arrow keys.
;;     If you press the left arrow key, it will continue to move left at a constant speed until you
;;     press the right arrow key.
;;
;;     The tank should fire missiles straight up from its current
;;     position when you press the space bar.
;;
;;     The invaders should appear randomly along the top of the screen and
;;     move at a 45 degree angle. When they hit a wall they will bounce off and
;;     continue at a 45 degree angle in the other direction.
;;
;;     When an invader reaches the bottom of the screen, the game is over.
;;
;; This is an example of what the game should look like during play. The arrows have been added on to show you how the different parts of the game move.
;; Designing this program will require many of the things you have learned throughout the course, and it will be the largest program you have worked on. Before downloading the starter file on the next page, take some time to become acquainted with the game, and complete the domain analysis for the program.
;; Submit your domain analysis in the box below for self assessment.


;; Constants:

(define WIDTH  300)
(define HEIGHT 500)

(define INVADER-X-SPEED 1.5)  ;speeds (not velocities) in pixels per tick
(define INVADER-Y-SPEED 1.5)
(define TANK-SPEED 2)
(define MISSILE-SPEED 10)

(define HIT-RANGE 10)
;; i don't know what are these lol
(define INVADE-RATE 100)

(define BACKGROUND (empty-scene WIDTH HEIGHT))

(define INVADER
  (overlay/xy (ellipse 10 15 "outline" "blue")              ;cockpit cover
              -5 6
              (ellipse 20 10 "solid"   "blue")))            ;saucer

(define TANK
  (overlay/xy (overlay (ellipse 28 8 "solid" "black")       ;tread center
                       (ellipse 30 10 "solid" "green"))     ;tread outline
              5 -14
              (above (rectangle 5 10 "solid" "black")       ;gun
                     (rectangle 20 10 "solid" "black"))))   ;main body

(define TANK-HEIGHT/2 (/ (image-height TANK) 2))
(define TANK-Y (- HEIGHT TANK-HEIGHT/2))

(define MISSILE (ellipse 5 15 "solid" "red"))



;; Data Definitions:

(define-struct game (invaders missiles tank))
;; Game is (make-game  (listof Invader) (listof Missile) Tank)
;; interp. the current state of a space invaders game
;;         with the current invaders, missiles and tank position

;; Game constants defined below Missile data definition

#;
(define (fn-for-game s)
  (... (fn-for-loinvader (game-invaders s))
       (fn-for-lom (game-missiles s))
       (fn-for-tank (game-tank s))))



(define-struct tank (x dir))
;; Tank is (make-tank Number Integer[-1, 1])
;; interp. the tank location is x, HEIGHT - TANK-HEIGHT/2 in screen coordinates
;;         the tank moves TANK-SPEED pixels per clock tick left if dir -1, right if dir 1

(define T0 (make-tank (/ WIDTH 2) 1))   ;center going right
(define T1 (make-tank 50 1))            ;going right
(define T2 (make-tank 50 -1))           ;going left

#;
(define (fn-for-tank t)
  (... (tank-x t) (tank-dir t)))



(define-struct invader (x y dx))
;; Invader is (make-invader Number Number Number)
;; interp. the invader is at (x, y) in screen coordinates
;;         the invader along x by dx pixels per clock tick

(define I1 (make-invader 150 100 12))           ;not landed, moving right
(define I2 (make-invader 150 HEIGHT -10))       ;exactly landed, moving left
(define I3 (make-invader 150 (+ HEIGHT 10) 10)) ;> landed, moving right


#;
(define (fn-for-invader invader)
  (... (invader-x invader) (invader-y invader) (invader-dx invader)))


(define-struct missile (x y))
;; Missile is (make-missile Number Number)
;; interp. the missile's location is x y in screen coordinates

(define M1 (make-missile 150 300))                       ;not hit I1
(define M2 (make-missile (invader-x I1) (+ (invader-y I1) 10)))  ;exactly hit I1
(define M3 (make-missile (invader-x I1) (+ (invader-y I1)  5)))  ;> hit I1

#;
(define (fn-for-missile m)
  (... (missile-x m) (missile-y m)))



(define G0 (make-game empty empty T0))
(define G1 (make-game empty empty T1))
(define G2 (make-game (list I1) (list M1) T1))
(define G3 (make-game (list I1 I2) (list M1 M2) T1))

;; In the name of Allah, the most Gracious, the most Merciful
;; we will start by the tank and it's missiles
;; Functions:

;;;;;;;;;;;;;;;;;;;;
;;                ;;
;;      TANK      ;;
;;                ;;
;;;;;;;;;;;;;;;;;;;;


;; Tank -> Tank
;; produce the next tank position and direction
(check-expect (move-tank T0) (make-tank (+ (/ WIDTH 2) TANK-SPEED) 1))
(check-expect (move-tank T1) (make-tank (+ 50 TANK-SPEED) 1))
(check-expect (move-tank T2) (make-tank (- 50 TANK-SPEED) -1))
(check-expect (move-tank (make-tank 0 -1)) (make-tank (- (tank-x (make-tank 0 -1))
                                                         (* (tank-dir (make-tank 0 -1)) TANK-SPEED))
                                                      (* -1 (tank-dir (make-tank 0 -1)))))
(check-expect (move-tank (make-tank WIDTH 1)) (make-tank (- (tank-x (make-tank WIDTH 1))
                                                            (* (tank-dir (make-tank WIDTH 1)) TANK-SPEED))
                                                         (* -1 (tank-dir (make-tank WIDTH 1)))))

;(define (move-tank t) t)  ;stub  ;bro i am really confused

;<template use from Tank>

(define (move-tank t)
  (cond [(or (< (tank-x t) (/ (image-width TANK) 2))
             (> (tank-x t) (- WIDTH (/ (image-width TANK) 2))))
         (make-tank (- (tank-x t) (* (tank-dir t) TANK-SPEED)) (* -1 (tank-dir t)))]
        [else (make-tank (+ (tank-x t) (* (tank-dir t) TANK-SPEED)) (tank-dir t))]))


;; Game -> Image
;; render the current game frame (only for tank bro)
(check-expect (render-tank G0) (place-image TANK (tank-x (game-tank G0)) TANK-Y BACKGROUND))
(check-expect (render-tank G1) (place-image TANK (tank-x (game-tank G1)) TANK-Y BACKGROUND))
(check-expect (render-tank G2) (place-image TANK (tank-x (game-tank G2)) TANK-Y BACKGROUND))

;(define (render-tank g) BACKGROUND)  ;stub

;<template use from Tank>

(define (render-tank g)
  (place-image TANK (tank-x (game-tank g)) TANK-Y BACKGROUND))


;;;;;;;;;;;;;;;;;;;;;;;;
;;                    ;;
;;      MISSILES      ;;
;;                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;
(define MAX-MISSILES 25)


;; ListOfMissile -> ListOfMissile  (no data definition for this shi)
;; produces a new missile in a list of missiles when handle-key triggers it
(check-expect (shoot (tank-x (game-tank G0)) (game-missiles G0)) (cons (make-missile (tank-x T0) TANK-Y) (game-missiles G0)))
(check-expect (shoot (tank-x (game-tank G1)) (game-missiles G0)) (cons (make-missile (tank-x T1) TANK-Y) (game-missiles G1)))

;(define (shoot x lom) lom)  ; stub

;<idk where to take the template>

(define (shoot x lom)
  (cons (make-missile x TANK-Y) lom))


;; ListOfMissile -> ListOfMissile
;; produces the next x and y for every missile in thre list
(check-expect (move-missiles (list M1)) (list (make-missile (missile-x M1) (- (missile-y M1) MISSILE-SPEED))))
(check-expect (move-missiles (list (make-missile 40 50) M1))
              (list
               (make-missile 40 (- 50 MISSILE-SPEED))
               (make-missile (missile-x M1) (- (missile-y M1) MISSILE-SPEED))))
(check-expect (move-missiles (list (make-missile 60 70) (make-missile 40 50) M1))
              (list
               (make-missile 60 (- 70 MISSILE-SPEED))
               (make-missile 40 (- 50 MISSILE-SPEED))
               (make-missile (missile-x M1) (- (missile-y M1) MISSILE-SPEED))))

;(define (move-missiles lom) lom)  ;stub

;<idk where to take the template>

(define (move-missiles lom)
  (cond [(empty? lom) lom]
        [else (cons (make-missile (missile-x (first lom))
                                  (- (missile-y (first lom)) MISSILE-SPEED))
                    (move-missiles (rest lom)))]))


;; ListOfMissile Image -> Image
;; take a ListOfMissile, a background and place some images yo
(check-expect (render-missiles (game-missiles G0) (render-tank G0)) (render-tank G0))
(check-expect (render-missiles (game-missiles G2) (render-tank G2)) (place-image MISSILE (missile-x (first (game-missiles G2)))
                                                                                 (missile-y (first (game-missiles G2))) (render-tank G2)))
(check-expect (render-missiles (game-missiles G3) (render-tank G3))
              (place-image MISSILE (missile-x (first (game-missiles G3)))
                           (missile-y (first (game-missiles G3))) (place-image MISSILE
                                                                               (missile-x (first (rest (game-missiles G3))))
                                                                               (missile-y (first (rest (game-missiles G3)))) (render-tank G2))))

;(define (render-missiles lom i) i)  ;stub

;<idk where to take the template>

(define (render-missiles lom i)
  (cond [(empty? lom) i]
        [else (place-image MISSILE (missile-x (first lom))
                           (missile-y (first lom))
                           (render-missiles (rest lom) i))]))


;; ListOfMissile -> ListOfMissile
;; filters the list of missiles from the ones that are out of the scrren rn
(check-expect (filter-missiles empty) empty)
(check-expect (filter-missiles (list M1 M2 M3)) (list M1 M2 M3))
(check-expect (filter-missiles (list (make-missile (/ WIDTH 2) 0) M1 M2 M3)) (list (make-missile (/ WIDTH 2) 0)
                                                                                   M1 M2 M3))
(check-expect (filter-missiles
               (list (make-missile (/ WIDTH 2) (* -1 (/ (image-height MISSILE) 2))) M1 M2 M3))
              (list M1 M2 M3))
(check-expect (filter-missiles
               (list M1 (make-missile (/ WIDTH 2) (* -1 (/ (image-height MISSILE) 2))) M2 M3))
              (list M1 M2 M3))

;(define (filter-missiles lom) lom)  ;stub

;(no template)

(define (filter-missiles lom)
  (cond [(empty? lom) empty]
        [else (if (>=  (* -1 (/ (image-height MISSILE) 2)) (missile-y (first lom)))
                  (filter-missiles (rest lom))
                  (cons (first lom) (filter-missiles (rest lom))))]))


;;;;;;;;;;;;;;;;;;;;;;;;
;;                    ;;
;;      INVADERS      ;;
;;                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;
(define MAX-INVADERS 6)
(define INVADERS-DX 2)

;; ListOfInvaders -> ListOfInvaders
;; generates Invaders to fill the accepted amount
;; don't know how to put randomness in unit tests
(define (generate-invaders l)
  (cond [(> 6 (count l)) (generate-invaders (cons (make-invader (random (+ 5 (- WIDTH (/ (image-width INVADER) 2))))
                                                                (* -2 (image-height INVADER))
                                                                (if (= (random 2) 1)
                                                                    INVADERS-DX
                                                                    (* INVADERS-DX -1))) l))]
        [else l]))


;; ListOfInvaders Image -> Image
;; take a game, a background and place some images yo
(check-expect (render-invaders (game-invaders G0) (render-tank G0)) (render-tank G0))
(check-expect (render-invaders (game-invaders G2) (render-tank G2)) (place-image INVADER (invader-x (first (game-invaders G2)))
                                                                                 (invader-y (first (game-invaders G2))) (render-tank G2)))
(check-expect (render-invaders (game-invaders G3) (render-tank G3))
              (place-image INVADER (invader-x (first (game-invaders G3)))
                           (invader-y (first (game-invaders G3))) (place-image INVADER
                                                                               (invader-x (first (rest (game-invaders G3))))
                                                                               (invader-y (first (rest (game-invaders G3)))) (render-tank G2))))

;(define (render-invaders loi i) i)  ;stub

;<idk where to take the template>

(define (render-invaders loi i)
  (cond [(empty? loi) i]
        [else (place-image INVADER (invader-x (first loi))
                           (invader-y (first loi))
                           (render-invaders (rest loi)
                                            i))]))


;; ListOfInvaders -> ListOfInvadrers
;; moves the list of invaders
(check-expect (move-invaders empty) empty)
(check-expect (move-invaders (list I1)) (list (make-invader (+ (invader-x I1) (* (invader-dx I1) INVADER-X-SPEED))
                                                            (+ (invader-y I1) INVADER-Y-SPEED)
                                                            (invader-dx I1))))
(check-expect (move-invaders (list (make-invader 150 100 -12) I1))
              (list (make-invader (+ (invader-x I1) (* (* -1 (invader-dx I1)) INVADER-X-SPEED))
                                  (+ (invader-y I1) INVADER-Y-SPEED)
                                  (* -1 (invader-dx I1)))
                    (make-invader (+ (invader-x I1) (* (invader-dx I1) INVADER-X-SPEED))
                                  (+ (invader-y I1) INVADER-Y-SPEED)
                                  (invader-dx I1))))
(check-expect (move-invaders (list (make-invader (- WIDTH (/ (image-width INVADER) 2)) (/ HEIGHT 2) 12)))
              (list (make-invader (- WIDTH (/ (image-width INVADER) 2)) (/ HEIGHT 2) -12)))
(check-expect (move-invaders (list (make-invader (/ (image-width INVADER) 2) (/ HEIGHT 2) -12)))
              (list (make-invader (/ (image-width INVADER) 2) (/ HEIGHT 2) 12)))

;(define (move-invaders lom) lom)  ; stub

;<no template>

(define (move-invaders loi)
  (cond [(empty? loi) empty]
        [else (cond
                [(and (> 0 (invader-dx (first loi))) (>= (/ (image-width INVADER) 2) (invader-x (first loi))))
                 (cons (make-invader
                        (invader-x (first loi))
                        (invader-y (first loi))
                        (* -1 (invader-dx (first loi))))
                       (move-invaders (rest loi)))]
                [(and (<= 0 (invader-dx (first loi))) (<= (- WIDTH (/ (image-width INVADER) 2)) (invader-x (first loi))))
                 (cons (make-invader
                        (invader-x (first loi))
                        (invader-y (first loi))
                        (* -1 (invader-dx (first loi))))
                       (move-invaders (rest loi)))]
                [else (cons (make-invader (+ (invader-x (first loi)) (* (invader-dx (first loi)) INVADER-X-SPEED))
                                          (+ (invader-y (first loi)) INVADER-Y-SPEED) (invader-dx (first loi)))
                            (move-invaders (rest loi)))])]))


;;;;ENRIQUE(fastest);;;;;
;;                     ;;  
;;      CONNECTED      ;;
;;                     ;;  
;;;;;;;;;;;;;;;;;;;;;;;;;

;; may Allah give you power and visison you loved brother
;; The main idea is
;;  - to make a function that takes a one invader and list of missiles
;;     - compares the invader to the list until the first missile who touch it
;;     - if true both the missile and the invader get removed from the list
;;     - else nothing happens
;;  - make a function that compares every single invader by using the function descriped 4 lines above
;;     - then it produces a list of those invaders
;; make a function that takes that list from the above and deletes the invaders and missiles in these coords
;; that should be optimized ik but idk how

;;;; Invader ListOfMissile -> ListOfMissile (if you wanna this work when it touches it,
;;;;   now i am working on them being overlayed)
;; Invader ListOfMissile -> Boolean
;; produces a true if there is a missile(s) in the same spot of the invader
(check-expect (invader-hitted? I1 empty) false)
(check-expect (invader-hitted? (make-invader (/ WIDTH 5) (/ HEIGHT 5) 2) (list M1 M2 M3)) false)
(check-expect (invader-hitted? (make-invader (/ WIDTH 5) (/ HEIGHT 5) 2) (list M1 M2
                                                                               (make-missile (/ WIDTH 5) (/ HEIGHT 5)) M3))
              true)
(check-expect (invader-hitted? (make-invader (/ WIDTH 5) (/ HEIGHT 5) 2) (list (make-missile (/ WIDTH 5) (/ HEIGHT 5))))
              true)

;(define (invader-hitted? i lom) false)  ;stub

;<no template>

;; claude helped me here i was using = he told me to use git range
(define (invader-hitted? i lom)
  (cond [(empty? lom) false]
        [else (if (and (>= (+ (invader-x i) HIT-RANGE) (missile-x (first lom)) (- (invader-x i) HIT-RANGE)) (>= (+ (invader-y i) HIT-RANGE) (missile-y (first lom)) (- (invader-y i) HIT-RANGE)))
                       true 
                       (invader-hitted? i (rest lom)))]))
;; it's just the same so i didont make a lot of shi about
(define (missile-hitted? loi m)
  (cond [(empty? loi) false]
        [else (if (and 
                       (>= (+ (missile-x m) HIT-RANGE) (invader-x (first loi)) (- (missile-x m) HIT-RANGE))
                       (>= (+ (missile-y m) HIT-RANGE) (invader-y (first loi)) (- (missile-y m) HIT-RANGE)))
                       true 
                       (missile-hitted? (rest loi) m))]))


;; ListOfInvader ListOfMissile -> ListOfInvader
;; produces a list of hitted invaders
(check-expect (rm-hitted-invaders empty (list M1 M2 M3)) empty)
(check-expect (rm-hitted-invaders (list I1 I2 I3) empty) (list I1 I2 I3))
(check-expect (rm-hitted-invaders empty empty) empty)
(check-expect (rm-hitted-invaders (list (make-invader (/ WIDTH 5) (/ HEIGHT 5) 2) (make-invader (/ WIDTH 5) (/ HEIGHT 7) 12))
                               (list (make-missile (/ WIDTH 2) (/ HEIGHT 2)) (make-missile (/ WIDTH 2) (/ HEIGHT 2))))
              (list (make-invader (/ WIDTH 5) (/ HEIGHT 5) 2) (make-invader (/ WIDTH 5) (/ HEIGHT 7) 12)))
(check-expect (rm-hitted-invaders (list (make-invader (/ WIDTH 2) (/ HEIGHT 2) 2) (make-invader (/ WIDTH 5) (/ HEIGHT 7) 12))
                               (list (make-missile (/ WIDTH 2) (/ HEIGHT 2)) (make-missile (/ WIDTH 2) (/ HEIGHT 2))))
              (list (make-invader (/ WIDTH 5) (/ HEIGHT 7) 12)))
(check-expect (rm-hitted-invaders (list (make-invader (/ WIDTH 3) (/ HEIGHT 3) 2) (make-invader (/ WIDTH 2) (/ HEIGHT 2) 2) (make-invader (/ WIDTH 5) (/ HEIGHT 7) 12))
                               (list (make-missile (/ WIDTH 2) (/ HEIGHT 2)) (make-missile (/ WIDTH 2) (/ HEIGHT 2))))
              (list (make-invader (/ WIDTH 3) (/ HEIGHT 3) 2) (make-invader (/ WIDTH 5) (/ HEIGHT 7) 12)))
(check-expect (rm-hitted-invaders (list (make-invader (/ WIDTH 3) (/ HEIGHT 3) 2) (make-invader (/ WIDTH 2) (/ HEIGHT 2) 2) (make-invader (/ WIDTH 5) (/ HEIGHT 7) 12))
                               (list (make-missile (/ WIDTH 3) (/ HEIGHT 3)) (make-missile (/ WIDTH 2) (/ HEIGHT 2)) (make-missile (/ WIDTH 2) (/ HEIGHT 2))))
              (list (make-invader (/ WIDTH 5) (/ HEIGHT 7) 12)))

;(define (rm-hitted-invaders loi lom) loi)  ;stub

;<no template>

(define (rm-hitted-invaders loi lom)
  (cond [(or (empty? loi) (empty? lom)) loi]
        [else (if (invader-hitted? (first loi) lom)
                  (rm-hitted-invaders (rest loi) lom)
                  (cons (first loi) (rm-hitted-invaders (rest loi) lom)))]))


;; ListOfInvader ListOfMissile -> ListOfMissile
;; produces a list of hitted missiles
(check-expect (rm-hitted-missiles empty (list M1 M2 M3)) (list M1 M2 M3))
(check-expect (rm-hitted-missiles (list I1 I2 I3) empty) empty)
(check-expect (rm-hitted-missiles empty empty) empty)
(check-expect (rm-hitted-missiles (list (make-invader (/ WIDTH 2) (/ HEIGHT 2) 2) (make-invader (/ WIDTH 2) (/ HEIGHT 2) 2))
                               (list (make-missile (/ WIDTH 2) (/ HEIGHT 2)) (make-missile (/ WIDTH 5) (/ HEIGHT 7))))
              (list (make-missile (/ WIDTH 5) (/ HEIGHT 7))))
(check-expect (rm-hitted-missiles (list (make-invader (/ WIDTH 3) (/ HEIGHT 3) 2) (make-invader (/ WIDTH 2) (/ HEIGHT 2) 2) (make-invader (/ WIDTH 5) (/ HEIGHT 7) 12))
                               (list (make-missile (/ WIDTH 4) (/ HEIGHT 4)) (make-missile (/ WIDTH 2) (/ HEIGHT 2))))
              (list (make-missile (/ WIDTH 4) (/ HEIGHT 4))))
(check-expect (rm-hitted-missiles (list (make-invader (/ WIDTH 3) (/ HEIGHT 3) 2) (make-invader (/ WIDTH 2) (/ HEIGHT 2) 2) (make-invader (/ WIDTH 5) (/ HEIGHT 7) 12))
                               (list (make-missile (/ WIDTH 3) (/ HEIGHT 3)) (make-missile (/ WIDTH 2) (/ HEIGHT 2)) (make-missile (/ WIDTH 2) (/ HEIGHT 2)) (make-missile (/ WIDTH 5) (/ HEIGHT 9))))
              (list (make-missile (/ WIDTH 5) (/ HEIGHT 9))))
(check-expect (rm-hitted-missiles (list (make-invader (/ WIDTH 5) (/ HEIGHT 5) 2) (make-invader (/ WIDTH 5) (/ HEIGHT 7) 12))
                               (list (make-missile (/ WIDTH 2) (/ HEIGHT 2)) (make-missile (/ WIDTH 2) (/ HEIGHT 2))))
              (list (make-missile (/ WIDTH 2) (/ HEIGHT 2)) (make-missile (/ WIDTH 2) (/ HEIGHT 2))))

;(define (rm-hitted-missiles loi lom) loi)  ;stub

;<no template>

(define (rm-hitted-missiles loi lom)
  (cond [(or (empty? loi) (empty? lom)) lom]
        [else (if (missile-hitted? loi (first lom))
                  (rm-hitted-missiles loi (rest lom))
                  (cons (first lom) (rm-hitted-missiles loi (rest lom))))]))


;;;;;;;;;;;;;;;;;;;;;;;;
;;                    ;;
;;      big bang      ;;
;;                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;
;; Game -> Game
;; start the world with (main G0)
;;
(define (main g)
  (big-bang g                   ; Game
    (on-tick   tock)     ; Game -> Game
    (to-draw   render)   ; Game -> Image
    (stop-when invader-arrived?)      ; Game -> Boolean
    ;            (on-mouse  ...)      ; Game Integer Integer MouseEvent -> Game
    (on-key    handle-key)))    ; Game KeyEvent -> Game

;; Game -> Game
;; produce the next world thing
;; no tests because of randomdess thing
(define (tock g) (make-game (move-invaders (generate-invaders (rm-hitted-invaders (game-invaders g) (game-missiles g))))
                            (filter-missiles (move-missiles (rm-hitted-missiles (game-invaders g) (game-missiles g))))
                            (move-tank (game-tank g))))


;;; Game -> Image
;;; render the given game thing
(check-expect (render G0) (render-tank G0))
(check-expect (render G1) (render-invaders (game-invaders G1) (render-missiles (game-missiles G1) (render-tank G1))))
(check-expect (render G2) (render-invaders (game-invaders G2) (render-missiles (game-missiles G2) (render-tank G2))))
(check-expect (render G3) (render-invaders (game-invaders G3) (render-missiles (game-missiles G3) (render-tank G3))))

;(define (render g) BACKGROUND)  ;stub

;<no template>

; claude told me to remove it i swear it's and the height of missiles are only his addons
(define (render g) (render-invaders (game-invaders g) (render-missiles (game-missiles g) (render-tank g))))


;; Game KeyEvent -> Game
;; produces the right direction of a tank
(check-expect (handle-key G0 "left") (make-game empty empty (make-tank (/ WIDTH 2) -1)))   ;dir=1
(check-expect (handle-key G0 "right") (make-game empty empty T0))
(check-expect (handle-key G0 " ") (make-game empty (list (make-missile (tank-x T0) TANK-Y)) T0))
(check-expect (handle-key G0 "a") G0)

;(define (handle-key g ke) g)  ; stub

;<template use from the recipes book>

(define (handle-key g ke)
  (cond [(key=? ke "left") (make-game (game-invaders g) (game-missiles g) (make-tank (tank-x (game-tank g)) -1))]
        [(key=? ke "right") (make-game (game-invaders g) (game-missiles g) (make-tank (tank-x (game-tank g)) 1))]
        [(key=? ke " ") (make-game (game-invaders g) (shoot (tank-x (game-tank g)) (game-missiles g)) (game-tank g))]
        [else g]))


;; Game -> Boolean
;; for stop-when
;; produces true if an invader has hit the ground or the tank
;; assumes that the height is 500
;; works on the given settings of the tank like that it's in the same height always or shi
(check-expect (invader-arrived? (make-game empty empty T0)) false)   ;normal
(check-expect (invader-arrived? (make-game (list I1) empty T0)) false)
(check-expect (invader-arrived? (make-game (list I1 I1) empty T0)) false)
(check-expect (invader-arrived? (make-game (list I1 (make-invader (/ WIDTH 3) (+ TANK-Y (image-width TANK)) 2)) empty T0)) true)   
(check-expect (invader-arrived? (make-game (list (make-invader (/ WIDTH 3) (+ TANK-Y (image-width TANK)) 2) I1) empty T0)) true)

;(define (invader-arrived? g) false)   ;stub

;<no template>

;[(>= (invader-y (first (game-invaders g))) (- HEIGHT ( / (image-height INVADER) 2))) true]
(define (invader-arrived? g)
  (cond [(empty? (game-invaders g)) false]
        [else (cond [(>= (invader-y (first (game-invaders g))) (+ TANK-Y (image-height TANK))) true]
                    [else (invader-arrived? (make-game (rest (game-invaders g)) (game-missiles g) (game-tank g)))])]))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                           ;;
;;      GENERAL HELPERS      ;;
;;                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; List -> Integer
;; produces the count of elements in a given list
(check-expect (count empty) 0)
(check-expect (count (list 1 2 3 4 5 6 67 8 9 9 9 9 9 9 9 9 9)) 17)
(check-expect (count (list 1 2 3 4 5)) 5)

;(define (count l) 0)  ;stub

#;
(define (count l)   ;template
  (cond [(empty? l) (...)]
        [else (... (first l)
                   (count (rest l)))]))

(define (count l)
  (cond [(empty? l) 0]
        [else (+ 1
                 (count (rest l)))]))