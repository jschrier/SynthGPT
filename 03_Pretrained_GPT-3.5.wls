#!/usr/bin/env wolframscript
(* ::Package:: *)

SetDirectory@NotebookDirectory[];
<<"./src/gpt_queries.wl"
<<"./src/string_formatting.wl"

prompt = With[
	{allowedPrecursors = StringRiffle@Keys@Import["./data/precursors.json", "RawJSON"],
	template = Import["./prompts/base_prompt.txt"]},
	StringReplace["[[ALLOWED PRECURSORS]]" -> allowedPrecursors]@ template ];

session = setupChat[prompt, 0, "gpt-3.5-turbo-0125"];

(* 
evaluating each fold (~2000 test examples each) takes about 12 minutes using 4 requests.
NOTE: Even 4 workers can superpasss the token saturate the request token limits 
for a Level-3 or below account (we have Level-4 priviledges). Even you 
encounter this, you can modify the ParallelMap function in evaluatePrediction
to include a Pause[1] between each evaluation.
*)

(* top-1 *)
FileSystemScan[
	evaluatePrediction[session, 1, "./results/gpt-3.5"], 
	"./data/cross_validation"]



(* top-5 *)
FileSystemScan[
	evaluatePrediction[session, 5, "./results/gpt-3.5"], 
	"./data/cross_validation"]
