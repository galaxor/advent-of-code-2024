(def lines (line-seq (clojure.java.io/reader *in*)))

(defn get-column [lines n] (map #(nth % n) lines))

(defn columnize [lines] 
  (let [max-width (apply max (map #(count %) lines))]
    (map #(get-column lines %) (range 0 max-width))
  )
)

(def columns (columnize lines))

(defn blank-column? [column] (every? #(= % \space) column))

(defn column-groups [columns] 
  (let [column-groups (partition-by #(blank-column? %) columns)]
    (filter #(not (blank-column? (first %))) column-groups)
  )
)

(defn find-equation [column-group]
  (let [operator (first (filter #(not (= \space %)) (apply concat (map #(take-last 1 %) column-group))))
        numerals (map #(BigInteger. (clojure.string/trim (apply str %))) (map #(drop-last 1 %) column-group))
       ]
    (list operator numerals)
  )
)

(defn find-equations [column-groups]
  (map #(find-equation %) column-groups)
)

(defn do-equation [equation]
  (let [operator (first equation)
        operands (second equation)
       ]
    (case operator 
      \+ (apply + operands)
      \* (apply * operands)
    )
  )
)

(println (apply + (map do-equation (find-equations (column-groups columns)))))
