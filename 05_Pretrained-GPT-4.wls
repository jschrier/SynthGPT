#!/usr/bin/env wolframscript
(* ::Package:: *)

SetDirectory@NotebookDirectory[];
<<"./src/gpt_queries.wl"
<<"./src/string_formatting.wl"

prompt = With[
	{allowedPrecursors = StringRiffle@Keys@Import["./data/precursors.json", "RawJSON"],
	template = Import["./prompts/base_prompt.txt"]},
	StringReplace["[[ALLOWED PRECURSORS]]" -> allowedPrecursors]@ template ];

session = setupChat[prompt, 0, "gpt-4-0125-preview"];

(* top-1 *)
FileSystemScan[
	evaluatePrediction[session, 1, "./results/gpt-4"], 
	"./data/cross_validation"]
	
(* top-5 *)
FileSystemScan[
	evaluatePrediction[session, 5, "./results/gpt-4"], 
	"./data/cross_validation"]
