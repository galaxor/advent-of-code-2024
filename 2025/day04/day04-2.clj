(def papers-removed 0)

(def lines (line-seq (clojure.java.io/reader *in*)))
(def grid (apply vector lines))

(defn is-reachable-paper? [x top-line mid-line bot-line] 
  (let [papers-from-top (count (filter #(= \@ %) [(get top-line (dec x)) (get top-line x) (get top-line (inc x))]))
        papers-from-mid (count (filter #(= \@ %) [(get mid-line (dec x))                  (get mid-line (inc x))]))
        papers-from-bot (count (filter #(= \@ %) [(get bot-line (dec x)) (get bot-line x) (get bot-line (inc x))]))
        num-surrounding-papers (+ papers-from-top papers-from-mid papers-from-bot)
        is-paper? (= \@ (get mid-line x))
       ]
    (if (and is-paper? (< num-surrounding-papers 4)) 1 0)
  )
)

(defn removable-papers-in-line [{top-line :top-line, mid-line :mid-line, bot-line :bot-line}]
  (map #(is-reachable-paper? % top-line mid-line bot-line) (range 0 (count mid-line)))
)

(defn count-and-remove [{num-papers-removed :num-papers-removed, removal-grid :removal-grid}
                         {top-line :top-line, mid-line :mid-line, bot-line :bot-line}]
  (let [removable-papers-this-line (removable-papers-in-line {:top-line top-line, :mid-line mid-line, :bot-line bot-line})]

    {:num-papers-removed (+ num-papers-removed (apply + removable-papers-this-line))
     :removal-grid (conj removal-grid removable-papers-this-line)}
  )
)

(defn line-struct [grid y] {:top-line (get grid (dec y)), :mid-line (get grid y), :bot-line (get grid (inc y))})

(defn apply-removal-line [line mask] (apply str (map #(if (= %2 1) \. %1) line mask)))

(defn apply-removal [grid removal-grid] (apply vector (map apply-removal-line grid removal-grid)))


(defn removal-iteration [{num-papers-removed :num-papers-removed grid :grid}]
  (let [iteration-result 
        (reduce count-and-remove {:num-papers-removed 0, :removal-grid []} (map #(line-struct grid %) (range 0 (count grid))))]

    {:prev-num-papers-removed num-papers-removed
     :num-papers-removed (+ num-papers-removed (:num-papers-removed iteration-result))
     :grid (apply-removal grid (:removal-grid iteration-result))}
  )
)

(println (:num-papers-removed (first (take-last 1 (take-while #(< (:prev-num-papers-removed %) (:num-papers-removed %))
            (iterate removal-iteration {:prev-num-papers-removed -1 :num-papers-removed 0, :grid grid}))))))
