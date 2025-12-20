(def lines (line-seq (clojure.java.io/reader *in*)))

(def top-line nil)
(def mid-line nil)
(def bot-line nil)
(def tot-reachable-papers 0)

(defn is-reachable-paper? [x] 
  (let [papers-from-top (count (filter #(= \@ %) [(get top-line (dec x)) (get top-line x) (get top-line (inc x))]))
        papers-from-mid (count (filter #(= \@ %) [(get mid-line (dec x))                  (get mid-line (inc x))]))
        papers-from-bot (count (filter #(= \@ %) [(get bot-line (dec x)) (get bot-line x) (get bot-line (inc x))]))
        num-surrounding-papers (+ papers-from-top papers-from-mid papers-from-bot)
        is-paper? (= \@ (get mid-line x))
       ]
    (if (and is-paper? (< num-surrounding-papers 4)) 1 0)
  )
)

(doseq [line lines]
  (def top-line mid-line)
  (def mid-line bot-line)
  (def bot-line line)

  (def tot-reachable-papers (+ tot-reachable-papers (apply + (map is-reachable-paper? (range 0 (count mid-line))))))
)

(def top-line mid-line)
(def mid-line bot-line)
(def bot-line nil)
(def tot-reachable-papers (+ tot-reachable-papers (apply + (map is-reachable-paper? (range 0 (count mid-line))))))

(println tot-reachable-papers)
