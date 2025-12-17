(def full-line (read-line))

(def range-specs (clojure.string/split full-line #","))

(def sum-of-invalids 0)

(doseq [range-spec range-specs]
  (let [[range-start-str range-end-str] (clojure.string/split range-spec #"-")]

    (def range-start (BigInteger. range-start-str))
    (def range-end (BigInteger. range-end-str))

    (doseq [my-number (range range-start (inc range-end))]
      (def my-digits (str my-number))
      (def is-invalid? (re-find #"^0|^(\d+)\1$" my-digits))
      (when is-invalid? (println "Indictment!" my-number))
      (def sum-of-invalids (if is-invalid? (+ sum-of-invalids my-number) sum-of-invalids))
    )
  )
)

(println sum-of-invalids)
