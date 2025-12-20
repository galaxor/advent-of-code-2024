(def total-joltage 0N)
(def need-digits 2)

(def lines (line-seq (clojure.java.io/reader *in*)))

(defn largest-digit-starting-at-I-excluding-last-N [line starting-index exclude-count]
  (let [
        line-without-last-N-digits (subs line starting-index (- (count line) exclude-count))
        largest-digit (first (reverse (sort line-without-last-N-digits)))
        index-of-largest-digit (+ starting-index (clojure.string/index-of (subs line starting-index) largest-digit))
       ]

    {:largest-digit largest-digit, :next-start-index (inc index-of-largest-digit)}
  )
)

(doseq [line lines]
  (def start-index 0)
  (def digits [])

  (doseq [exclude-count (range 11 -1 -1)]
    (let [{largest-digit :largest-digit, next-start-index :next-start-index}
          (largest-digit-starting-at-I-excluding-last-N line start-index exclude-count)
         ]
      
      (def start-index next-start-index)
      (def digits (conj digits largest-digit))
    )
  )

  (def line-joltage (BigInteger. (apply str digits)))
  (def total-joltage (+ total-joltage line-joltage))
  (println "Line joltage:" line-joltage)
)

(println "Total joltage:" total-joltage)
