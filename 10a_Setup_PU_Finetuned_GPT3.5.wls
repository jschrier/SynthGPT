#!/usr/bin/env wolframscript
(* ::Package:: *)

SetDirectory@NotebookDirectory[];
<<"./src/fine_tuning.wl"

{positive, unlabeled} = Lookup[{"positive", "unlabeled"}]@ Lookup["train"]@
	Import["./data_MP/PU_train_test.json"];

(* create a balanced dataset of positive and unlabeled results*)
RandomSeed[2024];
data = With[
	{p = (#->"P")&/@ positive,
	 u = (#->"U")&/@ unlabeled[[;;Length[positive]]]},
	RandomSample@ Join[p, u]];

(* create training and validation JSONL files for use with OpenAI fine-tuning *)
MapThread[
	generateFineTuningData,
	{{"./data_MP/finetuning/validate_pu.jsonl", "./data_MP/finetuning/train_pu.jsonl"},
	TakeDrop[#, Floor[0.2 * Length[#]]]& @ data}];
	
