(def lines (line-seq (clojure.java.io/reader *in*)))

(defn point [line] (mapv #(Integer/parseInt %) (clojure.string/split line #",")))

(def points (map point lines))

(defn first-item-paired-with-each-other-one [items]
  (filter #(not (= nil (second %))) (map #(vector (first items) (first (drop (inc %) items))) (range 0 (count items))))
)

(defn all-pairs [items]
  (apply concat (filter #(not (= '() %)) (map #(first-item-paired-with-each-other-one (drop % items)) (range 0 (count items)))))
)

(defn area [[[x1 y1] [x2 y2]]] (* (inc (Math/abs (- x2 x1))) (inc (Math/abs (- y2 y1)))))

(defn all-areas [points] (map area (all-pairs points)))

(println (last (sort (all-areas points))))
