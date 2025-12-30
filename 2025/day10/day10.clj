(def lines (line-seq (clojure.java.io/reader *in*)))

; Parses a string like
; "[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}"
; Outputs the initial state of the lights, and the specification of the buttons (which lights do they toggle).

(defn parse-line [line] 
  (let [components (clojure.string/split line #" ")
        lights (mapv #(= % \#) (drop 1 (drop-last 1 (get components 0))))
        buttons (mapv #(map (fn [num] (Integer/parseInt num)) (clojure.string/split % #",")) (map #(subs % 1 (dec (count %))) (drop 1 (drop-last 1 components))))
       ]
    {:goal-lights lights
     :buttons buttons
    }
  )
)

(defn toggle-lamp [lights-state toggle-nth]
  (concat
    (take toggle-nth lights-state)
    (list (not (nth lights-state toggle-nth)))
    (drop (inc toggle-nth) lights-state)
  )
)

(defn push-button [lights-state toggle-indexes]
  (reduce
    toggle-lamp
    lights-state
    toggle-indexes
  )
)


(defn successor-states [buttons {lights-state :lights-state, history :history}]
  (map
    (fn [button] 
      {:history (conj history button)
       :lights-state (push-button lights-state button)
       }
    )
    buttons
  )
)

(defn name-state [{lights-state :lights-state}]
  (apply str (map #(if % \1 \0) lights-state))
)

(defn examine-state [buttons {seen-states :seen-states, queue :queue}]
  (let [examining-state (first queue)
        remaining-queue (rest queue)
       ]
    (if (contains? seen-states (name-state examining-state))
      {:seen-states seen-states, :queue remaining-queue}
      {:seen-states (conj seen-states (name-state examining-state)),
       :queue (concat remaining-queue (successor-states buttons examining-state))
      }
    )
  )
)

(defn goal-reached? [goal-lights {queue :queue}]
  (= goal-lights (:lights-state (first queue)))
)


(defn bfs [{buttons :buttons, goal-lights :goal-lights}]
  (let [seen-states (set '())
        queue [{:lights-state (for [x (range 0 (count goal-lights))] false), :history []}]
        searched-queue
          (first (drop-while #(not (goal-reached? goal-lights %)) (iterate #(examine-state buttons %) {:seen-states seen-states, :queue queue})))
        winning-state (first (:queue searched-queue))
       ]

    winning-state
  )
)

(defn search-machine [line]
  (bfs (parse-line line))
)

(println (apply + (map #(count (:history (search-machine %))) lines)))
