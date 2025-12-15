(def dial 50)
(def zeroes 0)

(def lines (line-seq (clojure.java.io/reader *in*)))

(doseq [line lines]
  (def direction (subs line 0 1))
  (def distance (Integer/parseInt (subs line 1)))

  (def signed-distance (* distance (if (= direction "L") -1 1)))
  (def unmodded-dial (+ dial signed-distance))
  (def old-dial dial)
  (def dial (mod unmodded-dial 100))

  (def full-spins (Math/abs (quot distance 100)))
  (def crossing
    (if (and 
          (not (= dial 0))
          (not (= old-dial 0))
          (or
            (and (= direction "L") (> dial old-dial))
            (and (= direction "R") (< dial old-dial))
          )
        )
      1 0
    )
  )

  (def zeroes (+ zeroes full-spins crossing))
  (def zeroes (if (= dial 0) (inc zeroes) zeroes))

  (println old-dial "+" signed-distance "=" dial "Full spins:" full-spins "Crossing" crossing "At zero:" (if (= dial 0) 1 0))
)

(println zeroes)
