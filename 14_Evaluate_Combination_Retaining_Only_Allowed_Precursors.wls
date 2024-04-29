#!/usr/bin/env wolframscript
(* ::Package:: *)

SetDirectory@ NotebookDirectory[];
<<"./src/string_formatting.wl"

(* combine two sets of predictions, retaining only allowed precursors *)
mergeAllowed[allowed_List][e1_Association, e2_Association]:= With[
	{p1 = Select[ContainsOnly[allowed]]@ e1["prediction"],
	p2 = Select[ContainsOnly[allowed]]@ e2["prediction"]},
	DeleteDuplicatesBy[Sort]@ Join[p1, p2]
]

(* overload to take a list of inputs *)
mergeAllowed[allowed_List][e1_List, e2_List]:= MapThread[mergeAllowed[allowed], {e1,e2}]

(* define a function to evaluate whether a match is correct for the combined list
by taking only the first 5 entries *)
matchQ[l_, ans_]:= precursorMatchQ[ans, Take[l, UpTo[5]]]

(* look up each cross validation batch and implement the combination strategy *)
evaluateCombination[allowed_][file_]:=With[
	{ft = Lookup["results"]@ Import["./results/gpt-3.5_finetune_rescore/"<>file,"RawJSON"],
	 el = Lookup["results"]@ Import["./results/elemwise/"<>file,"RawJSON"]},
	With[
		{answers = Lookup["answer"]@ el,
		combinedPredictions = mergeAllowed[allowed][ft, el]},
		N@ Mean@ Boole@ MapThread[matchQ, {combinedPredictions, answers}]]]
		


(* perform the calculation *)

allowedPrecursors = Keys@ Import["./data/precursors.json","RawJSON"];

evaluateCombination[allowedPrecursors]/@ 
	{"top5_random_cv1.json", "top5_random_cv2.json", "top5_random_cv3.json",
	"top5_random_cv4.json","top5_random_cv5.json"}
	
SetPrecision[#, 3]&@ Comap[{MinMax, Mean, Median}]@ %

 

