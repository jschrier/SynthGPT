(* ::Package:: *)

SetDirectory@ NotebookDirectory[];
<<"./src/statistical_baseline.wl"

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


(*** evaluate on CV 1 dataset ***)
{train, test} = Values@ Import["./data/cv_random1.json"];
N@ ResourceFunction["ProportionsBy"][withinElemwiseScopeQ]@ test

