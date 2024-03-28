#!/usr/bin/env wolframscript
(* ::Package:: *)

SetDirectory@NotebookDirectory[];
<<"./src/gpt_queries.wl"
<<"./src/string_formatting.wl"

prompt = With[
	{allowedPrecursors = StringRiffle@Keys@Import["./data/precursors.json", "RawJSON"],
	template = Import["./prompts/base_prompt.txt"]},
	StringReplace["[[ALLOWED PRECURSORS]]" -> allowedPrecursors]@ template ];

(* 
	unlike in our other examples, we have different models for each CV 
	we use these to create a list of essions, and then map the evaluation
	over the session - CV datafile pairs
*)

models = {"ft:gpt-3.5-turbo-0125:fordham-university:synthgptcv1:96xiuNzV",
		"ft:gpt-3.5-turbo-0125:fordham-university:synthgptcv2:96xySxKN",
		"ft:gpt-3.5-turbo-0125:fordham-university:synthgptcv3:96xiP1xw",
		"ft:gpt-3.5-turbo-0125:fordham-university:synthgptcv4:97Gkkwz3",
		"ft:gpt-3.5-turbo-0125:fordham-university:synthgptcv5:97H1oHBo"};

cvFiles = FileNames["*.json", "./data/cross_validation"];
sessions = setupChat[prompt, 0, #]&/@ models;

(* top-1 *)
MapThread[
	evaluatePrediction[#1, 1, "./results/gpt-3.5_finetune"][#2]&, 
	{sessions, cvFiles}];


(* top-5 *)
MapThread[
	evaluatePrediction[#1, 5, "./results/gpt-3.5_finetune"][#2]&, 
	{sessions, cvFiles}];
