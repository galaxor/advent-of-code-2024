(def lines (line-seq (clojure.java.io/reader *in*)))

; Parses a line like "hhh: ccc fff iii"
(defn parse-line [line]
  (let [source-and-dest (clojure.string/split line #":")
        source (first source-and-dest)
        dest-str (clojure.string/trim (second source-and-dest))
        dest (set (clojure.string/split dest-str #" "))
       ]
    {source dest}
  )
)

; Parses bunch of lines like "hhh: ccc fff iii"
; Returns a map that puts {source1 #{dest1 dest2 dest3}, ...}
(defn parse-input [lines]
  (reduce #(conj %1 (parse-line %2)) {} lines)
)

(defn combine-paths [source destination old-situation new-situation]
  (cond
    ; Source is fft.
    ; Upgrade paths that pass through neither to paths that pass through fft.
    ; Do not upgrade paths that pass through fft but not dac.
    ; Upgrade paths that pass through dac but not fft to paths that pass through both.
    ; Do not upgrade paths that pass through both.
    ; The upgrade only applies to paths coming from "old-situation".  The paths
    ; that already exist at new-situation came from somewhere other than this
    ; source.  So just add those on as is.
    (= source "fft")
      [
        ; Paths that pass through neither fft nor dac.
        (get (get new-situation destination [0 0 0 0]) 0)

        ; Paths that pass through fft but not dac.
        (+ (get (get old-situation source [0 0 0 0]) 0)
           (get (get old-situation source [0 0 0 0]) 1)
           (get (get new-situation destination [0 0 0 0]) 1)
        )

        ; Paths that pass through dac but not fft.
        (get (get new-situation destination [0 0 0 0]) 2)

        ; Paths that pass through both fft and dac.
        (+ (get (get old-situation source [0 0 0 0]) 2)
           (get (get old-situation source [0 0 0 0]) 3)
           (get (get new-situation destination [0 0 0 0]) 3)
        )
      ]

    ; Source is dac.
    ; Upgrade paths that pass through neither to paths that pass through dac.
    ; Upgrade paths that pass through fft but not dac to paths that pass through both.
    ; Do not upgrade paths that pass through dac but not fft.
    ; Do not upgrade paths that pass through both.
    ; The upgrade only applies to paths coming from "old-situation".  The paths
    ; that already exist at new-situation came from somewhere other than this
    ; source.  So just add those on as is.
    (= source "dac")
      [
        ; Paths that pass through neither fft nor dac.
        (get (get new-situation destination [0 0 0 0]) 0)

        ; Paths that pass through fft but not dac.
        (get (get new-situation destination [0 0 0 0]) 1)

        ; Paths that pass through dac but not fft.
        (+ (get (get old-situation source [0 0 0 0]) 0)
           (get (get old-situation source [0 0 0 0]) 2)
           (get (get new-situation destination [0 0 0 0]) 2)
        )

        ; Paths that pass through both fft and dac.
        (+ (get (get old-situation source [0 0 0 0]) 1)
           (get (get old-situation source [0 0 0 0]) 3)
           (get (get new-situation destination [0 0 0 0]) 3)
        )
      ]

    ; the default; don't upgrade any paths, just add what we know.
    true
      [
        ; Paths that pass through neither fft nor dac.
        (+ (get (get old-situation source [0 0 0 0]) 0)
           (get (get new-situation destination [0 0 0 0]) 0)
        )

        ; Paths that pass through fft but not dac.
        (+ (get (get old-situation source [0 0 0 0]) 1)
           (get (get new-situation destination [0 0 0 0]) 1)
        )

        ; Paths that pass through dac but not fft.
        (+ (get (get old-situation source [0 0 0 0]) 2)
           (get (get new-situation destination [0 0 0 0]) 2)
        )

        ; Paths that pass through both fft and dac.
        (+ (get (get old-situation source [0 0 0 0]) 3)
           (get (get new-situation destination [0 0 0 0]) 3)
        )
      ]
  )
)

; Each step takes a thing like this:
; {'aaa [1 0 2 0], 'bbb [0 0 1 2], 'ccc [3 0 0 0]}
; This means there is 1 way to get to aaa which does not pass through fft or
; dac; 0 ways which pass through fft but not dac; 2 ways that pass through dac
; but not fft; and 0 ways that pass through both fft and dac.  Etc.
; It builds up the new situation, which has the same structure.
; It considers each key-value pair, which represents [source, num-ways-to-source].  
; Look at the connectivity.

(defn step [connectivity old-situation] 
  (reduce 
    (fn [new-situation [source num-ways-to-source]]
      ; If there's a connection between out and something, ignore that.
      (if (= source "out") new-situation
        (let [destinations (get connectivity source)]
          ; For each destination.
          (reduce 
            (fn [new-situation destination]
              (assoc new-situation destination (combine-paths source destination old-situation new-situation))
            )
            new-situation
            destinations
          )
        )
      )
    )
    ; We build up the new situation anew for each step, but we accumulate all the ways to get to out.
    {"out" (get old-situation "out" [0 0 0 0])}
    old-situation 
  )
)

(defn paths-with-dac-and-fft [lines]
  (let [connectivity (parse-input lines)
        max-steps (count connectivity)
        paths (get (first (drop (dec max-steps) (iterate #(step connectivity %) {"svr" [1 0 0 0]}))) "out")
       ]
    paths
  )
)

(println (paths-with-dac-and-fft lines))
