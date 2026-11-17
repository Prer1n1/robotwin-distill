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
| NEW A: Teacher, CFG off @30 | 30 | 30 | 1.0 (CFG OFF) | none (1.0) | no | me | ____ % | predicted 5.82 s |
| NEW B: Teacher, CFG off @16 | 16 | 16 | 1.0 (CFG OFF) | none (1.0) | no | me | ____ % | assumed about 3.37 s |
| NEW C: Teacher, CFG off @8 | 8 | 8 | 1.0 (CFG OFF) | none (1.0) | no | me | ____ % | assumed about 1.97 s |

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
