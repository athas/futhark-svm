import "../../diku-dk/sorts/radix_sort"
import "util"
import "kernels"
import "solvers/kernel_chunk"

-- Requires y to be 0, 1, 2...
entry train [n][m] (X: [n][m]f32) (Y: [n]u8) (k_id: i32)
    (C: f32) (gamma: f32) (coef0: f32) (degree: f32)
    (eps: f32) (max_iter: i32) =
  let kernel = kernel_from_id k_id
  let p = {kernel, gamma, coef0, degree}
  let sorter = radix_sort_by_key (.0) u8.num_bits u8.get_bit
  let (Y, X) = unzip (sorter (zip Y X))
  -- t: Number of classes.
  let t = 1 + i32.u8 (u8.maximum Y)
  let n_models = (t * (t - 1)) / 2
  let counts = bincount t (map i32.u8 Y)
  let starts = exclusive_scan (+) 0 counts
  let out = replicate n_models (0, 0, 0, 0)
  -- TODO: Weights, Cp / Cn
  -- WC = map2 (*) C W
  -- then solve WC[i] WC[j]
  let (A_I, out, _) =
    loop (A_I, out, k) = ([], out, 0) for i < t do
      loop (A_I, out, k) = (A_I, out, k) for j in i + 1..<t do
        let (si, ci) = (starts[i], counts[i])
        let (sj, cj) = (starts[j], counts[j])
        let c = ci + cj
        let X_k = concat_to c X[si:si + ci] X[sj:sj + cj]
        let (I_k, Y_k) = unzip (map (\i ->
          if i < ci
          then (si + i, 1)
          else (sj + i - ci, -1)) (iota c))
        let (A_k, obj, rho, i) = solve X_k Y_k p C C eps max_iter
        -- Only keep non-zero alphas.
        -- Should use a tiny threshold mby
        let A_I_k = filter ((.0) >-> (!=0)) (zip A_k I_k)
        let out[k] = (length A_I_k, obj, rho, i)
        in (A_I ++ A_I_k, out, k + 1)
  let (A, I) = unzip A_I
  let (sizes, O, R, iter) = unzip4 out
  -- Remove the samples from X that aren't used as support vectors.
  -- We do this by finding B_s[i] which is 1 if X[i] is used as a
  -- support vector and 0 if not.
  let bins = replicate n false
  let trues = map (\_ -> true) I
  let B_s = reduce_by_index bins (||) false I trues
  let (_, S) = unzip (filter (.0) (zip B_s X))
  -- Remap indices for support vectors.
  let remap = scan (+) 0 (map i32.bool B_s)
  let I' = map (\i -> remap[i] - 1) I
  in (A, I', S, sizes, R, O, iter, t)

entry predict [n][m][o][v][s] (X: [n][m]f32) (S: [o][m]f32)
    (A: [v]f32) (I: [v]i32) (rhos: [s]f32) (sizes: [s]i32)
    (t: i32) (k_id: i32) (gamma: f32) (coef0: f32) (degree: f32)
    (ws: i32) =
  let kernel = kernel_from_id k_id
  let p = {kernel, gamma, coef0, degree}
  let is = triu_indices t :> [s](i32, i32)
  let F = segmented_replicate sizes (iota s) :> [v]i32
  let (P, _) = loop (P, i) = ([], 0) while i < n do
    let to = i32.min (i + ws) n
    let K = kernel_matrix p X[i:to] S
    let P_i = map (\K_i ->
      let dK_i = map (\j -> K_i[j]) I
      let prods = map2 (*) dK_i A
      -- Find decision values (without rho).
      let dvs = reduce_by_index (replicate s 0) (+) 0 F prods
      let decisions = map3 (\s rho (i, j) ->
        if s > rho then i else j) dvs rhos is
      let votes = bincount t decisions
      let max_by_fst a b = if a.0 > b.0 then a else b
      let v_c = reduce max_by_fst (0, -1) (zip votes (iota t))
      in v_c.1) K
    in (P ++ P_i, i + ws)
  in P
