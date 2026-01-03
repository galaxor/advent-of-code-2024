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


; Each step takes a thing like this:
; {'aaa 1, 'bbb 0, 'ccc 3}
; This means there is 1 way to get to aaa, 0 ways to get to bbb, and 3 ways to get to ccc.
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
              (assoc new-situation destination (+ (get old-situation source 0) (get new-situation destination 0)))
            )
            new-situation
            destinations
          )
        )
      )
    )
    ; We build up the new situation anew for each step, but we accumulate all the ways to get to out.
    {"out" (get old-situation "out" 0)}
    old-situation 
  )
)

(def connectivity (parse-input lines))

(def max-steps (count connectivity))

(println (first (drop (dec max-steps) (iterate #(step connectivity %) {"you" 1}))))
