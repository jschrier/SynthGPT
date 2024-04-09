#!/usr/bin/env wolframscript
(* ::Package:: *)

(* create summary scores for the PU learning tasks *)

(*** define functions for summarization ***)

Clear[summarize]
(* map over files in a particular folder  *)
summarize[folder_?DirectoryQ]:= With[
	{files = FileNames["batch*.json", folder],
	outputFile = folder<>"/summary.json"},
	Export[outputFile, #, "Compact"->2]&@ Map[summarize]@ files;]
	
(* summarize results from one CV run *)
summarize[f_?FileExistsQ]:= With[
	{d = Import[f, "RawJSON"]},
	With[
		{measurements = ClassifierMeasurements[
			Query["results", All, "prediction"]@d, 
			Query["results", All, "answer"]@d]},
			
		<|"dataset" -> Query["metadata", "datasource"]@ d,
		"accuracy" -> measurements["Accuracy"],
		"recall"-> measurements["Recall"->"P"],
		"mcc"->measurements["MatthewsCorrelationCoefficient"->"P"],
		"n_correct" -> Total@ Boole@ Query["results", All, "correctQ"]@ d,
		"n_test" -> Query["results", Length]@ d|>]]




(*  compute the summary statistics, saving result into file  *)
SetDirectory@NotebookDirectory[];

summarize/@ {"./results_MP/gpt-3.5", "./results_MP/gpt-3.5_finetune", "./results_MP/gpt-4"}
