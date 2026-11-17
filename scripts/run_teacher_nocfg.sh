#!/usr/bin/env bash
# Untrained teacher with video CFG OFF (policy.guidance_scale=1.0) on the frozen seed list.
# Identical to run_teacher_frozen.sh except for the one added --policy.guidance_scale flag.
# Usage:
#   scripts/run_teacher_nocfg.sh <run_name> --nfe 16 [extra eval_frozen.py flags]
# Verify after the run: summary.md must show "guidance 1.0/<action value>" for this run.
set -euo pipefail
source "$(dirname "$0")/../env.sh"
RUN=${1:?run name}; shift || true
TEACHER_REV=6d128a33268a8abb558bfc12d0f2d4e0225d7d64                 # lerobot/lingbot_va_robotwin
WAN=$HF_HOME/hub/models--robbyant--lingbot-va-base/snapshots/68b7bc1b35da6ddc67ea94c4ceb58d768fbb3f9c
cd "$ROBOTWIN_ROOT"
python "$PROJ/scripts/eval_frozen.py" --seeds "$PROJ/eval/seeds/v1/frozen_seeds.json" --run-name "$RUN" "$@" -- \
  --policy.path=lerobot/lingbot_va_robotwin --policy.pretrained_revision=$TEACHER_REV \
  --policy.wan_pretrained_path="$WAN" --policy.device=cuda \
  --policy.guidance_scale=1.0 \
  --env.type=robotwin --env.task=beat_block_hammer --env.action_mode=ee \
  --seed=1000 --output_dir="$PROJ/eval/results/$RUN/lerobot_cfg"
echo "results: $PROJ/eval/results/$RUN"
