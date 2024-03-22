# SynthGPT
 
# Leaderboard (performance on CV1 split)

Evaluation on getting all precursors correct, given target, evaluated on 2109 target items, containing only precursors that appear >=5 times in the dataset.

| Method          | Cost (USD) | Top-1 | Top 5 |
| :-----           | :-------  | ----: |-----: |
| Weighted random | 0          |  0.35 | 0.55  |
| GPT-3.5 (zero shot) | $4  |  0.37 | 0.48  |
| GPT-3.5 (fine tuned)| $10 training + $15 eval | 0.59 | 0.65 |
| GPT-4 (zero shot) | $63 | 0.40 | 0.51 |
