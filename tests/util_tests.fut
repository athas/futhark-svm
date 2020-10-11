import "../lib/github.com/fzzle/futhark-svm/util"

-- ==
-- entry: test_triu
-- input { 3 } output { [0, 0, 1] [1, 2, 2] }
-- input { 5 } output {
--   [0, 0, 0, 0, 1, 1, 1, 2, 2, 3]
--   [1, 2, 3, 4, 2, 3, 4, 3, 4, 4] }
-- input { 10 } output {
--   [0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
--    1, 1, 1, 1, 1, 1, 1, 2, 2, 2,
--    2, 2, 2, 2, 3, 3, 3, 3, 3, 3,
--    4, 4, 4, 4, 4, 5, 5, 5, 5, 6,
--    6, 6, 7, 7, 8]
--   [1, 2, 3, 4, 5, 6, 7, 8, 9, 2,
--    3, 4, 5, 6, 7, 8, 9, 3, 4, 5,
--    6, 7, 8, 9, 4, 5, 6, 7, 8, 9,
--    5, 6, 7, 8, 9, 6, 7, 8, 9, 7,
--    8, 9, 8, 9, 9] }
entry test_triu (n: i32) =
  unzip (triu (i64.i32 n) |> map (\(x,y) -> (i32.i64 x, i32.i64 y)))

-- ==
-- entry: test_segmented_replicate
-- input { [3] [0] } output { [0, 0, 0] }
-- input { [1, 2, 4] [0, 1, 2] } output { [0, 1, 1, 2, 2, 2, 2] }
entry test_segmented_replicate [n] (ns: [n]i32) (vs: [n]i32) =
  segmented_replicate (map i64.i32 ns) vs

-- ==
-- entry: test_exclusive_scan
-- input { [1] } output { [0] }
-- input { [3, 2] } output { [0, 3] }
-- input { [1, 2, 3, 4] } output { [0, 1, 3, 6] }
entry test_exclusive_scan [n] (vs: [n]i32) =
  exclusive_scan (+) 0 vs

-- ==
-- entry: test_bincount
-- input { 5 [0] } output { [1, 0, 0, 0, 0] }
-- input { 3 [0, 0, 1, 1, 2, 2] } output { [2, 2, 2] }
-- input { 5 [0, 3, 4, 1, 3] } output { [1, 1, 0, 2, 1] }
entry test_bincount [n] (k: i32) (vs: [n]i32) =
  bincount (i64.i32 k) (map i64.i32 vs)

-- ==
-- entry: test_find_unique
-- input { 5 [1, 2, 3] } output { -1 }
-- input { 2 [1, 2, 3] } output { 1 }
entry test_find_unique [n] (v: i32) (vs: [n]i32) =
  i32.i64 (find_unique (i64.i32 v) (map i64.i32 vs))
