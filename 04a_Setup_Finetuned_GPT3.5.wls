#!/usr/bin/env wolframscript
(* ::Package:: *)

SetDirectory@NotebookDirectory[];
<<"./src/fine_tuning.wl"

(* generate JSON-LD files to upload to the OpenAI website *)

fineTuneSplit[f_?FileExistsQ]:= With[
	{trainFile = StringTemplate["./data/finetuning/train_``.jsonl"]@ FileBaseName[f],
	validationFile = StringTemplate["./data/finetuning/validate_``.jsonl"]@ FileBaseName[f],
	trainingData = Lookup["train"]@ Import[f]},
	MapThread[
		generateFineTuningData,
		{{validationFile, trainFile},
		TakeDrop[train, Floor[Length[train]/5]]}];]

(* map over cross validation sets *)
FileSystemScan[fineTuneSplit, "./data/cross_validation/"];

(* 

after this is complete, follow the instructions on 
https://platform.openai.com/docs/guides/fine-tuning 
to upload the resulting files and have OpenAI perform the finetuning 
with default hyperparameters 

As of March 2024, fine-tuning each of these datasets with gpt-3.5-turbo 
costs about $11 USD and takes about 90 minutes.
 *)
