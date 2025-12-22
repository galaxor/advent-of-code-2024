(def lines (line-seq (clojure.java.io/reader *in*)))

(def split-lines (map #(clojure.string/split (clojure.string/trim %) #"\s+") lines))

(defn extract-columns [split-lines] (map (fn [whichth] (map #(nth % whichth) split-lines)) (range 0 (count (first split-lines)))))

(def equations (extract-columns split-lines))

(defn do-equations [equations]
  (map (fn [equation]
          (let [operator (last equation)
                operands (map #(BigInteger. %) (drop-last 1 equation))
               ]
            (case operator 
              "+" (apply + operands)
              "*" (apply * operands)
            )
          )
       )
    equations
  )
)

(println (apply + (do-equations equations)))
