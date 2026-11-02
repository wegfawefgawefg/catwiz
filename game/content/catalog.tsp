; the catalog: every face's and charm's record on the second disk, laid out by the build from
; their rows (content/faces.tsp, content/charm_rows.tsp), so the number of faces and charms costs
; no memory (docs/faces.md). A record is one sector, a face's at its row's place in FACES, a
; charm's in CHARMS:
;   0 slot (a charm: its kind)   1 amount   2 step (a charm: when)   3 cost (a charm: its mark)
;   4 aim   5 tags   6 show   7 the name's place   8 the text's place
;   9-98 the card picture (art/pictures: 15 rows of 6 bytes, two pixels a byte)
;   99 on: the steps (content/steps step_bytes: their own lines after the stop), then the name
;   and the text, each ending with a 0; zeros to the sector's end
; and the draws' pools (FACE_POOL, CHARM_POOL: a count, then a row a card). content/items reads
; records into memory, only between fights (when an offer is drawn, at a run's start).

(import state)
(import content/action ac)
(import content/steps)
(import content/shows)
(import content/encounters enc)
(import content/faces)
(import content/charm_rows)
(import art/pictures)

(const PICTURE_AT u8 9)
(const STEPS_AT u8 99)
(const NAME_LONGEST u8 17)
(const PART_LONGEST u8 35) ; a text's part, its # counted as two digits
(const UP u8 128)          ; a pool's card of 128 + a slot: a level on that slot

; a row's field key (:name ...), or none's (a default, or an error for one a row must have)
(macro field (row key none)
    (let props (tail row))
    (for k 0 (len props)
        (if (= (nth props k) key)
            (return (nth props (+ k 1)))))
    (if (= none 'need)
        (error "catalog: " (head row) " has no " key))
    none)

; the fields a row may have, so a typo fails the build
(macro check_fields (row keys)
    (let props (tail row))
    (if (!= (% (len props) 2) 0)
        (error "catalog: " (head row) ": a field without its value"))
    (for k 0 (len props)
        (if (= (% k 2) 0)
            (do
                (let known false)
                (for j 0 (len keys)
                    (if (= (nth keys j) (nth props k))
                        (set known true)))
                (if (not known)
                    (error "catalog: " (head row) " has no field " (nth props k)))))))

; the text's parts (split by |) each fit a row
(macro check_text (row text)
    (let codes (chars text))
    (let n 0)
    (for i 0 (+ (len codes) 1)
        (if (or (= i (len codes)) (= (nth codes i) 124))
            (do
                (if (> n PART_LONGEST)
                    (error "catalog: "
                        (head row)
                        "'s text has a part of " n
                        " columns (a # counts 2), " PART_LONGEST " at most: " text))
                (set n 0))
            (set n
                (+ n (if (= (nth codes i) 35)
                    2
                    1))))))

; a record's 256 bytes: top (the 7 bytes before the places), the picture, the steps, the name
; and the text
(macro record (row top name text steps_rows picture)
    (if (> (len (chars name)) NAME_LONGEST)
        (error "catalog: " (head row) "'s name is longer than " NAME_LONGEST ": " name))
    (check_text row text)
    (let st (steps.step_bytes steps_rows))
    (let name_at (+ STEPS_AT (len st)))
    (let text_at (+ name_at (+ (len (chars name)) 1)))
    (let bytes
        (append top
            (list name_at text_at)
            (pictures.picture picture)
            st
            (chars name)
            (list 0)
            (chars text)
            (list 0)))
    (if (> (len bytes) 256)
        (error "catalog: "
            (head row)
            "'s record is "
            (len bytes)
            " bytes, a sector at most: shorten its text or steps"))
    (append bytes (repeat (- 256 (len bytes)) 0)))

; a face's tags (content/action), from its words
(macro tag_bits (row words)
    (let out 0)
    (for i 0 (len words)
        (set out
            (list '+ out (match (nth words i)
                ('three 'ac.THREE)
                ('kittens 'ac.KITTENS)
                ('grows 'ac.GROWS)
                ('plus 'ac.CAP_PLUS)
                ('times 'ac.CAP_TIMES)
                ('none 'ac.CAP_NONE)
                ('hp 'ac.HP)
                (_ (error "catalog: " (head row) " has no tag " (nth words i)))))))
    out)

(macro face_record (row)
    (check_fields row
        (list :name :text :slot :amount :step :cost :aim :tags :show :picture :weight :steps))
    (record row
        (list `(as u8 ,(symbol 'ac.Slot. (field row :slot 'need)))
            (field row :amount 'need)
            (field row :step 0)
            (field row :cost 0)
            `(as u8 ,(symbol 'state.Aim. (field row :aim 'need)))
            (tag_bits row (field row :tags (list)))
            (symbol 'shows. (field row :show 'NONE)))
        (field row :name 'need)
        (field row :text 'need)
        (field row :steps (list))
        (field row :picture 'need)))

(macro charm_record (row)
    (check_fields row (list :name :text :kind :amount :when :mark :picture :weight :steps))
    (let mark (chars (field row :mark 'need)))
    (if (!= (len mark) 1)
        (error "catalog: " (head row) "'s mark is one glyph"))
    (record row
        (list `(as u8 ,(symbol 'enc.CharmKind. (field row :kind 'need)))
            (field row :amount 'need)
            `(as u8 ,(symbol 'steps.When. (field row :when 'none)))
            (nth mark 0)
            0 0 0)
        (field row :name 'need)
        (field row :text 'need)
        (field row :steps (list))
        (field row :picture 'need)))

; the records, a sector each, as a table on disk 2 (its record in aux memory, as every disk
; table's: draw/meter)
(macro table (name which)
    (let rows (if (= which 'faces)
        (faces.rows)
        (charm_rows.rows)))
    (let bytes (list))
    (for i 0 (len rows)
        (set bytes
            (append bytes (if (= which 'faces)
                (face_record (nth rows i))
                (charm_record (nth rows i))))))
    `(const ,name (array u8 ,(len bytes)) (make (array u8 ,(len bytes)) ,@bytes) :on disk2 :in aux))

; the faces' draw: a count, then each face that can be offered (weight not 0) as its id, weight
; and slot, then the six upgrades (UP + the slot); the charms': a count, then id and weight
(macro face_pool ()
    (let rows (faces.rows))
    (let bytes (list))
    (let n 0)
    (for i 0 (len rows)
        (let w (field (nth rows i) :weight 0))
        (if (> w 0)
            (do
                (set bytes
                    (append bytes
                        (list i w `(as u8 ,(symbol 'ac.Slot. (field (nth rows i) :slot 'need))))))
                (set n (+ n 1)))))
    (let ups (faces.upgrades))
    (for s 0 (len ups)
        (set bytes (append bytes (list (+ UP s) (nth ups s) s)))
        (set n (+ n 1)))
    (if (> n 85)
        (error "catalog: the faces' pool has " n " rows, 85 at most (a sector)"))
    `(const FACE_POOL (array u8 ,(+ 1 (len bytes)))
        (make (array u8 ,(+ 1 (len bytes))) ,n ,@bytes)
        :on disk2
        :in aux))

(macro charm_pool ()
    (let rows (charm_rows.rows))
    (let bytes (list))
    (let n 0)
    (for i 0 (len rows)
        (let w (field (nth rows i) :weight 0))
        (if (> w 0)
            (do
                (set bytes (append bytes (list i w)))
                (set n (+ n 1)))))
    `(const CHARM_POOL (array u8 ,(+ 1 (len bytes)))
        (make (array u8 ,(+ 1 (len bytes))) ,n ,@bytes)
        :on disk2
        :in aux))

(face_pool)
(charm_pool)

; the records after the pools, the faces' then the charms' (the pool and the faces it draws a
; few tracks apart at most)
(table FACES faces)
(table CHARMS charms)

; a face's or charm's id (its row's place) by its name: (catalog.id TWIG_WAND)
(macro place (rows name what)
    (for i 0 (len rows)
        (if (= (head (nth rows i)) name)
            (return i)))
    (error "catalog: no " what " " name))

(macro id (name)
    (place (faces.rows) name "face"))

(macro charm_id (name)
    (place (charm_rows.rows) name "charm"))

(macro face_count ()
    (len (faces.rows)))

(macro charm_count ()
    (len (charm_rows.rows)))

(const FACE_COUNT u8 (face_count))
(const CHARM_COUNT u8 (charm_count))
