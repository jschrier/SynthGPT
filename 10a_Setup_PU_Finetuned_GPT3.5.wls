#!/usr/bin/env wolframscript
(* ::Package:: *)

SetDirectory@NotebookDirectory[];
<<"./src/fine_tuning.wl"

{positive, unlabeled} = Lookup[{"positive", "unlabeled"}]@ Lookup["train"]@
	Import["./data_MP/PU_train_test.json"];

RandomSeed[2024];
data = With[
	{p = (#->"P")&/@ positive[[1;;100]],
	 u = (#->"U")&/@ unlabeled[[1;;860]]},
	RandomSample@ Join[p, u]];

MapThread[
	generateFineTuningData,
	{{"./data_MP/finetuning/validate_pu.jsonl", "./data_MP/finetuning/train_pu.jsonl"},
	TakeDrop[#, Floor[0.2 * Length[#]]]& @ data}];
	
