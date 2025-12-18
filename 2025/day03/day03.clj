(def total-joltage 0N)

(def lines (line-seq (clojure.java.io/reader *in*)))

(doseq [line lines]
  (def line-without-last-digit (subs line 0 (dec (count line))))

  (def largest-digit (first (reverse (sort line-without-last-digit))))
  (def index-of-largest-digit (clojure.string/index-of line largest-digit))
  (def second-largest-digit (first (reverse (sort (subs line (inc index-of-largest-digit))))))

  (def line-joltage (Integer/parseInt (str largest-digit second-largest-digit)))
  (def total-joltage (+ total-joltage line-joltage))
  (println "Line joltage:" line-joltage)
)

(println "Total joltage:" total-joltage)
