# SynthGPT
 
# Early result (on our first attempt to split data, on CV1)

We need to redo these results with the new way of defining the duplicate precursors.  It will not change the statistical baseline, it will not change zero-shot GPT, but it will change the fine-tuned GPT. Also it will change ElemWise 

Evaluation on getting all precursors correct, given target, evaluated on 2109 target items, containing only precursors that appear >=5 times in the dataset.

| Method          | Cost (USD) | Top-1 | Top-5 |
| :-----           | :-------  | ----: |-----: |
| Statistical baseline | 0          |  0.35 | 0.55  |
| GPT-3.5 (zero shot) | $4  |  0.37 | 0.48  |
| GPT-3.5 (fine tuned)| $10 training + $15 eval | 0.59* | 0.65* |
| GPT-4 (zero shot) | $63 | 0.40 | 0.51 |
| ElemWise |       |  0.76  |        0.85  |
| Hypothetical perfect Elemwise |   | 0.86  |  -- |


# Synthesizability prediction result (Preliminary result)
To evaluate synthesizability prediction task, we can calculate true positive rate (TPR) or recall.
The other metrics such as false positive rate (FPR) and precision (PREC) can be measured by alpha estimation.

| Method              | Threshold  | Cost (USD) |  TPR | FPR* | PREC* |
| :-----              | :-------   | :-------   | ----:| ----:| ----: |
| GPT-3.5 (zero shot) |            |            |      |      |       |
| GPT-3.5 (fine tuned)| 0.86       |            | 0.74 | 0.02 |  0.75 |
| stoi-CGNF           | 0.75       |            | 0.82 | 0.02 |  0.82 |
| GPT-3.5 (fine tuned)| 0.50       |            | 0.95 | 0.12 |  0.41 |
| stoi-CGNF           | 0.50       |            | 0.94 | 0.08 |  0.50 |
| stoi-similarity baseline  |  -   |            | 0.61 | 0.03 |  0.61 |

(FPR* and PREC* are estimated values.)
