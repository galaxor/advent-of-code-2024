(def lines (line-seq (clojure.java.io/reader *in*)))

(defn evolve-position [prev-line this-line position]
  (if (= prev-line nil) {:split? false, :symbol (nth this-line position)}
    (let [laser-from-above (and (not (= (nth this-line position) \^)) (some #(= (nth prev-line position) %) '(\S \|)))
          laser-from-left-split (if (< (dec position) 0) 
                                  false 
                                  (and (= (nth this-line (dec position)) \^) (= (nth prev-line (dec position)) \|))
                                )
          laser-from-right-split (if (>= (inc position) (count this-line))
                                   false
                                   (and (= (nth this-line (inc position)) \^) (= (nth prev-line (inc position)) \|))
                                 )
          split-here (and (= (nth this-line position) \^) (= (nth prev-line position) \|))
          new-symbol-this-position (if (or laser-from-above laser-from-left-split laser-from-right-split) \| (nth this-line position))
        ]
      {:split? split-here, :symbol new-symbol-this-position}
    )
  )
)

(defn evolve-line [prev-line this-line]
  (let [evolved-positions (map #(evolve-position prev-line this-line %) (range 0 (count this-line)))
        num-splits (count (filter identity (map #(:split? %) evolved-positions)))
        evolved-line (apply str (map #(:symbol %) evolved-positions))
       ]
    {:num-splits num-splits, :evolved-line evolved-line}
  )
)

(defn evolve-lines [lines]
  (reduce
    (fn [{num-splits :num-splits, prev-line :prev-line} this-line]
      (let [evolved-this-line (evolve-line prev-line this-line)]
        {:num-splits (+ num-splits (:num-splits evolved-this-line))
         :prev-line (:evolved-line evolved-this-line)
        }
      )
    )
    {:num-splits 0, :prev-line nil}
    lines
  )
)

(println (:num-splits (evolve-lines lines)))
