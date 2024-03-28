#!/usr/bin/env wolframscript
(* ::Package:: *)

(* create summary scores for the GPT-3.5 and GPT-4 outputs *)

(*** define functions for summarization ***)
(* summarize results from one CV run *)
summarize[f_?FileExistsQ]:= With[
	{d = Import[f, "RawJSON"]},
	<|"dataset" -> Query["metadata", "datasource"]@ d,
	"accuracy" -> N@ Mean@ Boole@ Query["results", All, "correctQ"]@ d,
	"n_correct" -> Total@ Boole@ Query["results", All, "correctQ"]@ d,
	"n_test" -> Query["results", Length]@ d|>]

(* map over files in a particular folder and grouping (e.g., top1, top5) *)
summarize[folder_, group_]:= With[
	{files = FileNames[group<>"_*.json", folder],
	outputFile = folder<>"/summary_"<>group<>".json"},
	Export[outputFile, #, "Compact"->2]&@ Map[summarize]@ files;]


(*  compute the summary statistics *)
SetDirectory@NotebookDirectory[];

directories = {"./results/gpt-3.5", "./results/gpt-3.5_finetune", "./results/gpt-4"};
groups = {"top1", "top5"}; 

Outer[summarize, directories, groups];


(*** 
Despite the instructions not to do so, the GPT models sometimes add erroneous O2 or H2O
which causes the prediction to not match.

Go back to manually rescore these entries and recompute...
***)

(* make a copy of the original results *)
CopyDirectory[#, #<>"_rescore"]&/@ directories;


(*** define rescoring functions ***)

(* remove offending species *)
removeO2[l_List]:= DeleteCases[l, "O2", Infinity]
removeH2O[l_List]:= DeleteCases[l, "H2O", Infinity]

(* rescore one row of entries *)
rescore[row_Association]:=With[
	{newPrediction = removeH2O@ removeO2@ Lookup["prediction"]@ row,
	actual = Lookup["answer"]@ row},
	(* advanced Association trick for value replacement, see:
		 https://mathematica.stackexchange.com/a/54745/63709 *) 
	<|row,
	"correctQ"->precursorMatchQ[actual, newPrediction],
	"prediction"->newPrediction|>]

(* map over the entire list of entries *)
rescore[data_List]:=rescore/@data

(* update metadata with current time and rescoring indication *)
updateMetadata[original_Association]:=
	<|original,
	"date" -> DateString["ISODateTime"],
	"notes" -> "rescored after removing O2 and H2O"|>

(* overloaded version: apply to a file, and rewrite to the same file *)
rescore[f_?FileExistsQ]:= With[
	{d = Import[f, "RawJSON"]},
	Export[f, #, "Compact"->2]&@
		<|"metadata" -> updateMetadata@ Lookup["metadata"]@ d,
		"results" -> rescore@ Lookup["results"]@ d|>]


(* apply to the new files *)
FileSystemScan[rescore, #<>"_rescore", FileNameForms->"*cv*.json"]&/@ directories;


(* recompute summary statistics*)
Outer[summarize, (#<>"_rescore"&/@directories), groups];


(* summarize random baseline result*)
summarize["./results/statistical_baseline",#]&/@groups;
