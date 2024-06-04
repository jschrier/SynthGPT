# `PU_composition_2020.json`

Inorganic composition data with icsd-tag (1; synthesized positive data, 0; not-yet-synthesized unlabeled data)

Retrieved at Feb. 2020 from MP and OQMD database.

-------------------------------------------------
**Data size :**

393,053 unique compositions (69,905 from MP, 303,587 from OQMD, and 19,561 common in both databases)
- 40,817 synthesized data (33,185 from MP, 7,632 from both MP and OQMD)
- 352,236 not-yet-synthesized data (36,720 from MP, 303,587 from OQMD, and 11,929 common in both databases)

# `PU_train_test.json`

Processed train/test split used for all models.

# `/finetuning`

Contains JSONL files with the training (`train_pu.jsonl`) and validation (`validate_pu.jsonl`) files used for fine-tuning the GPT-3.5 model with the default prompt