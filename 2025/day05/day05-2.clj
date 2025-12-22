(def lines (line-seq (clojure.java.io/reader *in*)))

(def range-lines (take-while #(> (count %) 0) lines))

(def inventory-lines (drop (inc (count range-lines)) lines))
(def inventory (map #(BigInteger. %) inventory-lines))

(def ranges (apply vector (map #(vector (BigInteger. (first %)), (BigInteger. (second %))) 
              (map #(clojure.string/split % #"-") range-lines))))

(defn within-range-fn [range] #(and (>= % (first range)) (<= % (second range))))

(defn sort-by-first [coll] (sort #(compare (first %1) (first %2)) coll))

(defn merge-ranges [range1 range2]
  (let [overlap? (or ((within-range-fn range1) (first range2))
                     ((within-range-fn range1) (second range2))
                     ((within-range-fn range2) (first range1))
                     ((within-range-fn range2) (second range1))
                 )
       ]

    (if overlap?
      (vector (vector (min (first range1) (first range2)) (max (second range1) (second range2))))
      (vector range2 range1)
    )
  )
)

(defn attempt-merge [{left :left, right :right}]
  (if (= [] right) {:left left, :right nil}
    (let [subject (first right)
          before left
          after (apply vector (rest right))
          merged-before (map #(merge-ranges subject %) before)
          merged-after (map #(merge-ranges subject %) after)
          successes-before (map #(< (count %) 2) merged-before)
          successes-after (map #(< (count %) 2) merged-after)
          any-successes? (or (some identity successes-before) (some identity successes-after))
          output-left (apply vector (map first merged-before))
        ]

      {:left (if any-successes? output-left (conj output-left subject))
       :right (apply vector (map first merged-after))}
    )
  )
)

(def merged-ranges (:left (last (take-while #(not (= nil (:right %))) (iterate attempt-merge {:left [], :right ranges})))))

(println (apply + (map #(inc (- (second %) (first %))) merged-ranges)))
