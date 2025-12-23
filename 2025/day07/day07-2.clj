(def lines (line-seq (clojure.java.io/reader *in*)))

(defn evolve-position [prev-line this-line position]
  (if (= prev-line nil) (if (= (nth this-line position) \S) 1 0)
    (let [timelines-from-above (if (= (nth this-line position) \^)
                                   0
                                   (nth prev-line position)
                               )

          timelines-from-left-split (if (< (dec position) 0) 
                                        0
                                        (if (= (nth this-line (dec position)) \^)
                                            (nth prev-line (dec position))
                                            0
                                        )
                                    )

          timelines-from-right-split (if (>= (inc position) (count this-line)) 
                                        0
                                        (if (= (nth this-line (inc position)) \^)
                                            (nth prev-line (inc position))
                                            0
                                        )
                                     )
          timelines-that-get-here (+ timelines-from-above timelines-from-left-split timelines-from-right-split)
        ]
      timelines-that-get-here
    )
  )
)

(defn evolve-line [prev-line this-line]
  (map #(evolve-position prev-line this-line %) (range 0 (count this-line)))
)

(defn evolve-lines [lines]
  (reduce evolve-line nil lines)
)

(println (apply + (evolve-lines lines)))
