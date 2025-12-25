(def lines (line-seq (clojure.java.io/reader *in*)))

(defn read-point [line] [line (mapv #(BigInteger. %) (clojure.string/split line #","))])

(defn distance [[x1 y1 z1] [x2 y2 z2]] (Math/sqrt (+ (Math/pow (- x2 x1) 2) (Math/pow (- y2 y1) 2) (Math/pow (- z2 z1) 2))))

(defn point-pair-distance [[pointA-name pointA-coords] [pointB-name pointB-coords]]
  (let [[point-alpha point-beta] (if (> 0 (compare pointA-name pointB-name))
                                     [[pointA-name pointA-coords] [pointB-name pointB-coords]]
                                     [[pointB-name pointB-coords] [pointA-name pointA-coords]]
                                 )
        [point-alpha-name point-alpha-coords] point-alpha
        [point-beta-name point-beta-coords] point-beta
       ]

    [(str point-alpha-name "-" point-beta-name) [point-alpha-coords point-beta-coords (distance point-alpha-coords point-beta-coords)]]
  )
)

(defn distance-with-each-other-point [pointA points]
  (mapv #(point-pair-distance pointA %) points)
)

(defn all-distance-pairs [points]
  (apply concat (map #(distance-with-each-other-point (nth points %) (drop (inc %) points)) (range 0 (count points))))
)

(def points (map read-point lines))

(def distance-map (all-distance-pairs points))

(def points-to-join (map #(drop-last 1 (second %)) (sort-by #(nth (second %) 2) distance-map)))

(defn init-disjoint-set [points] (apply hash-map (apply concat (map-indexed #(let [[point-name point-coords] %2] [point-name [point-coords %1]]) points))))

(def sets (init-disjoint-set points))

(defn name-point [[x y z]] (str x "," y "," z))

(def point-names-to-join (map #(let [[point-a point-b] %] [(name-point point-a) (name-point point-b)]) points-to-join))

(defn union [sets [point-name-a point-name-b]]
  (let [[point-a-coords old-set] (get sets point-name-a)
        [point-b-coords new-set] (get sets point-name-b)
       ]
    (apply hash-map (apply concat (map (fn [[point-name [point-coords point-set]]] [point-name [point-coords (if (= point-set old-set) new-set point-set)]]) sets)))
  )
)

(defn count-sets [sets] (count (set (map #(second (second %)) sets))))

(defn join-points [sets point-names-to-join] (first (drop-while #(> (count-sets (first %)) 1) (reductions #(vector (union (first %1) %2) %2) [sets nil] point-names-to-join))))

(def joined-sets (join-points sets point-names-to-join))

(println (apply * (map first (map second (map read-point (second joined-sets))))))
