#!/usr/bin/env wolframscript
(* ::Package:: *)

(* Elemwise reactions must obey two criteria:  
1. each precursor element in the target is used only once ... *)

noRepeatedSourceElementPrecursorsQ[precursors_List]:=
	DuplicateFreeQ@ Map[Intersection[sourceElements, hasElements[#]]&]@ precursors

(*
2. and only precursors that contain a source element are generated... *)

noNonsourcePrecursorsQ[precursors_List]:=
	Not@ ContainsAny[{{}}]@ Map[Intersection[sourceElements, hasElements[#]]&]@ precursors

(* to be in scope, both of the above must be false *)
withinElemwiseScopeQ[precursors_List]:=
	noRepeatedSourceElementPrecursorsQ[precursors] && noNonsourcePrecursorsQ[precursors]

(* overload to handle a reaction record with multiple precursor sets *)
withinElemwiseScopeQ[target_->precursors_]:=
	AnyTrue[withinElemwiseScopeQ]@ precursors
	
(* generate summary statistics from cross-validation file *)
estimatePerfectElemwise[f_?FileExistsQ]:=With[
	{result = CountsBy[withinElemwiseScopeQ]@ Lookup["test"]@Import[f]},
	<|"dataset" -> f,
	"accuracy" -> N[result[True]/Total[result]],
	"n_correct" -> result[True],
	"n_test" -> Total[result]|>]


(*** perform evaluate on CV 1 dataset ***)
SetDirectory@ NotebookDirectory[];
<<"./src/statistical_baseline.wl"

Export["./results/perfect_elemwise/summary_top1.json", #, "Compact"->2]&@
	Values@ FileSystemMap[estimatePerfectElemwise, "./data/cross_validation"]
