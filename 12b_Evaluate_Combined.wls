#!/usr/bin/env wolframscript
(* ::Package:: *)

SetDirectory@ NotebookDirectory[];
<<"./src/gpt_queries.wl"
<<"./src/combined.wl"
<<"./src/string_formatting.wl"


session = With[
	{prompt = Import["./prompts/reevaluate_plans_prompt.txt"]},
	setupChat[prompt, 0, "gpt-4-0125-preview"]];
	
FileSystemScan[
	evaluateCombination[session, "./results/combined/"],
	"./data/combined/cv1/",
	FileNameForms->"*.json"]





