# Predictions: teacher with video CFG off (guidance_scale=1.0), written BEFORE any run

Question: does DMD2 training add anything beyond "fewer steps + CFG off"?
Runs planned: untrained teacher, guidance_scale=1.0, NFE 30 / 16 / 8, on the frozen 200 scenes.

## B2. Latency model: latency = overhead + steps x cost_per_step

### Worked example (Rachel's CFG-on controls)
- points: 30 steps -> 7.36 s, 16 steps -> 4.24 s
- cost per step = (7.36 - 4.24) s / (30 - 16) steps = 3.12 / 14 = 0.223 s/step
- overhead = 7.36 - 30 x 0.223 = 7.36 - 6.69 = 0.67 s
- test on unseen point: 8 steps -> 0.67 + 8 x 0.223 = 2.45 s vs measured 2.39 s (off by 0.06 s, good fit)

### CFG-off line (Rachel's students as proxy)
- points: 16 steps -> 3.37 s, 8 steps -> 1.97 s
- time saved = 3.37 - 1.97 = 1.40 s; steps removed = 16 - 8 = 8 steps
- cost per step = 1.40 s / 8 steps = 0.175 s/step
- overhead = 1.97 - 8 x 0.175 = 1.97 - 1.40 = 0.57 s
- PREDICTION, NFE 30, CFG off: 0.57 + 30 x 0.175 = 0.57 + 5.25 = 5.82 s per chunk
- NFE 16 and NFE 8 are not independent predictions: I used them to fit the line (3.37 s and 1.97 s).
- Per-step saving vs CFG on: (0.223 - 0.175) / 0.223 = 0.048 / 0.223 = about 21.5%
- Why only ~21% and not 50%: (fill in your own words; see notes below)
- Assumptions: latency is linear in steps (only 2 points per line, no third point to test the CFG-off line);
  an untrained teacher with CFG off costs the same per step as a merged student.

## B3. Full comparison table (n = 200 frozen scenes, noise about +/- 2.4 points)

| Run | Video steps | Action steps | Video CFG | Action CFG | LoRA trained? | Who ran it | Success | Median latency per chunk |
|---|---|---|---|---|---|---|---|---|
| Teacher @30 | 30 | 30 | 5.0 (CFG ON) | none (1.0) | no | Rachel | 194/200 = 97.0% | 7.36 s |
| Control-16 | 16 | 16 | 5.0 (CFG ON) | none (1.0) | no | Rachel | 193/200 = 96.5% | 4.24 s |
| Control-8 | 8 | 8 | 5.0 (CFG ON) | none (1.0) | no | Rachel | 192/200 = 96.0% | 2.39 s |
| Student-16 | 16 | 16 | 1.0 (CFG OFF) | none (1.0) | yes (DMD2) | Rachel | 195/200 = 97.5% | 3.37 s |
| Student-8 | 8 | 8 | 1.0 (CFG OFF) | none (1.0) | yes (DMD2) | Rachel | 188/200 = 94.0% | 1.97 s |
| NEW A: Teacher, CFG off @30 | 30 | 30 | 1.0 (CFG OFF) | none (1.0) | no | me | not run | predicted 5.82 s (untested) |
| NEW B: Teacher, CFG off @16 | 16 | 16 | 1.0 (CFG OFF) | none (1.0) | no | me | **184/199 = 92.5%** (guess was 95%) | 4.31 s on my A100 pod (not comparable to Rachel's hardware) |
| NEW C: Teacher, CFG off @8 | 8 | 8 | 1.0 (CFG OFF) | none (1.0) | no | me | not run | assumed about 1.97 s (untested) |

My success-rate guesses, one reason each:
- NEW A (@30, CFG off): 96 %   because:lot of steps to correct errors,From Rachel's controls model is robust to changes in step count
- NEW B (@16, CFG off): 95 %   because:Fewer steps plus no guidance
- NEW C (@8,  CFG off): 93 %   because: Fewest steps and no guidance

## B4. Self-check (rewrite each in your own words)

1. Why does guidance_scale=1.0 give only the conditional prediction?
   The guided formula is v_uncond + w × (v_cond − v_uncond). At w = 1 it becomes v_uncond + v_cond − v_uncond = v_cond, so the unconditional pass isn't needed and can be skipped, which saves compute.

2. Why doesn't Student-16 vs Control-16 show what training did on its own?
   The student differs from the control in THREE things: fewer steps (same as control), CFG off, and the trained LoRA.
   The control changes only the steps. So any gap mixes the CFG effect and the training effect.

3. If CFG-off teacher at NFE 16 scores about 97%, what do I conclude? About 93%?
   About 97% matches Student-16 (97.5%) without any training, so on this benchmark the student's accuracy comes from fewer steps and CFG off, and training added nothing measurable. About 93% is about 4.5 points below Student-16, so removing CFG hurts an untrained model and the LoRA recovered the loss. That gap is about two standard errors, so I would call it suggestive, not proven. Anything in between (around 95%) is inside the noise and inconclusive.

## Results: NEW B only (CFG-off teacher @16), run 2026-11-19 on an A100 SXM 80 GB pod

Run: `scripts/run_teacher_nocfg.sh nocfg16_full --nfe 16 --no-video`, manifest shows `guidance_scale: 1.0`.
Per-episode results: `eval/nocfg16_episodes.csv`. 199 scenes, 0 errors.

**Success: 184/199 = 92.5%** (95% Wilson interval 87.9% to 95.4%). My guess was 95%, so I was 2.5 points too high.

| Task | Success |
|---|---|
| blocks_ranking_rgb | 20/20 |
| open_laptop | 17/20 |
| pick_dual_bottles | 20/20 |
| place_burger_fries | 20/20 |
| place_can_basket | 15/20 |
| place_cans_plasticbox | 20/20 |
| place_fan | 19/20 |
| place_mouse_pad | 15/19 (seed 100008 skipped, see below) |
| place_object_basket | 19/20 |
| stamp_seal | 19/20 |

### The two comparisons this run was for (unpaired z-tests on the totals)
- **CFG effect = my run vs Control-16 (same steps, CFG on, no LoRA):** 92.5% vs 96.5% = -4.0 points.
  SE = sqrt(0.9246 x 0.0754 / 199 + 0.965 x 0.035 / 200) = sqrt(0.000350 + 0.000169) = 0.0228, so z = 0.0404 / 0.0228 = 1.77, p about 0.08. Suggestive, not significant.
- **Training effect = Student-16 vs my run (same steps, CFG off, LoRA added):** 97.5% vs 92.5% = +5.0 points.
  SE = sqrt(0.000350 + 0.975 x 0.025 / 200) = sqrt(0.000350 + 0.000122) = 0.0217, so z = 0.0504 / 0.0217 = 2.32, p about 0.02.
- Reading: on these scenes, turning CFG off cost the untrained teacher about 4 points, and the DMD2 student ended above that. So the training added something beyond "fewer steps + CFG off". This matches my "about 93%" branch in self-check question 3.

### Caveats
- **199 scenes, not 200.** `place_mouse_pad` seed 100008 hung the simulator twice (log froze after about 34 and about 9 steps, GPU at 0%). I skipped it with the new `--skip-scenes place_mouse_pad:100008` flag. If it counted as a failure: 184/200 = 92.0%, same conclusion.
- **Different hardware** from Rachel's runs (my A100 SXM pod). Results may differ slightly even in deterministic mode.
- **Unpaired tests.** A paired McNemar test on the same scenes needs Rachel's per-episode results for Control-16 and Student-16 (requested).
- **One run, noise about +/- 2.4 points.** Failures: place_can_basket 5, place_mouse_pad 4, open_laptop 3, place_fan 1, place_object_basket 1, stamp_seal 1.
- **Latency:** median chunk latency 4.31 s (1,649 chunks) on my pod. It is not comparable to Rachel's table (different machine), and I did not run CFG-on on this pod, so this run cannot say whether CFG-off saves time. The 3.37 s I assumed above is untested.
- NEW A (NFE 30) and NEW C (NFE 8) were not run.

### What I got wrong / what I learned (edit in your own words)
- I guessed 95% because "fewer steps plus no guidance" sounded like a small penalty. The measured penalty was about 4 points against the CFG-on control.
- I treated the latency model as a prediction, but it came from one machine's two data points, so it cannot be tested on a different machine.
- The run needed a harness change (`--skip-scenes`) because one scene hangs the simulator. The harness has no per-episode timeout, so a hung scene stalls the whole run silently. Log timestamps, not progress-bar text, show whether a run is alive.
