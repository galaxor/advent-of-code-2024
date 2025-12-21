(def lines (line-seq (clojure.java.io/reader *in*)))

(def range-lines (take-while #(> (count %) 0) lines))

(def inventory-lines (drop (inc (count range-lines)) lines))
(def inventory (map #(BigInteger. %) inventory-lines))

(def ranges (map #(vector (BigInteger. (first %)), (BigInteger. (second %))) 
              (map #(clojure.string/split % #"-") range-lines)))

(defn within-range-fn [range] #(and (>= % (first range)) (<= % (second range))))
; (defn within-any-range-fn [ranges] (apply #(or %&) (map within-range-fn ranges)))

(def all-range-fns (map within-range-fn ranges))
(defn within-any-range? [x] (some identity (map #(%1 x) all-range-fns)))

(println (count (filter identity (map within-any-range? inventory))))
