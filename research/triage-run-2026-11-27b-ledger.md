# Triage run 2026-11-27 (twentieth), research rows

| Issue | Check | Result | Outcome |
|---|---|---|---|
| 102 nvidia-smi `-f` empty files | Cluster test on a 1-GPU short-partition job, 7 s, 2 s interval: (a) `stdbuf -oL ... -f file &` then `kill`; (b) same without stdbuf; (c) `stdbuf -oL ... > file &` then `kill`; (d) foreground `timeout 7 ... -f file` | (a) 0 bytes, (b) 0 bytes, (c) 147 bytes, (d) 147 bytes | `stdbuf` does not matter. Background `-f` + `kill` loses all samples; stdout redirect and foreground `-f` under timeout both write. Cause of (a)/(b) unexplained. Proposed fix: sampler writes via stdout redirect. |
| 203 create_labeled_video | Signature printed in DLC 3.0.3 (cluster env): `shuffle`, `trainingsetindex`, `track_method`, `modelprefix`, `plot_bboxes`, `pcutoff`, `overwrite`, `max_workers`; no scorer argument | file is located from config + shuffle | partly answered; H5 naming still needs a test |
| 187, 188 | not yet checked | | needs-info |
| Login node | `nvidia-smi` absent on login node; GPU partitions: gpu-short (2 h), gpu, gpu-l40s, gpu-h200; default partition has no GPUs, so `--gres` alone fails | | note for hpc-gpu-jobs test advice |
