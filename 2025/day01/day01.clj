(def dial 50)
(def zeroes 0)

(def lines (line-seq (clojure.java.io/reader *in*)))

(doseq [line lines]
  (def direction (subs line 0 1))
  (def distance (Integer/parseInt (subs line 1)))

  (def signed-distance (* distance (if (= direction "L") -1 1)))
  (def old-dial dial)
  (def dial (mod (+ dial signed-distance) 100))
  ; (println old-dial "+" signed-distance "=" dial)
  
  (def zeroes (if (= dial 0) (inc zeroes) zeroes))
)

(println zeroes)
