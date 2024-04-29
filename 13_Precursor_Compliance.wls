#!/usr/bin/env wolframscript
(* ::Package:: *)

SetDirectory@ NotebookDirectory[];
allowedPrecursors = Keys@ Import["./data/precursors.json","RawJSON"];

(* functions to perform the compliance checks *)
(* take as input a list of lists of predicted precursors *)
fractionReactionsInCompliance[precursorsUsed_List]:=
	N@ Mean@ Boole@ Map[ContainsOnly[allowedPrecursors]]@ Flatten[ precursorsUsed, 1]

fractionTop5AllInCompliance[precursorsUsed_List]:=
	N@ Mean@ Boole@ Map[AllTrue[ContainsOnly[allowedPrecursors]]]@ precursorsUsed

(* check one file *)
precursorCompliance[file_?FileExistsQ]:= With[
	{p = Lookup["prediction"]@ Lookup["results"]@ Import[file, "RawJSON"]},
	Comap[{fractionReactionsInCompliance, fractionTop5AllInCompliance}]@ p]
	
(* look up results of all top5 (returned as an Association) 
 and return mean for each quantity *)
precursorComplianceSummary[folder_]:=With[
	{results = FileSystemMap[predictionCompliance, folder, FileNameForms->"top5_*.json"]},
	SetPrecision[#, 2]&@ Map[Mean]@ Transpose@ Values@ results]

		

(* perform the calculation *)
AssociationMap[
	precursorComplianceSummary,
	{"./results/gpt-3.5_rescore", "./results/gpt-4_rescore",
	 "./results/gpt-3.5_finetune_rescore", "./results/elemwise"}]
