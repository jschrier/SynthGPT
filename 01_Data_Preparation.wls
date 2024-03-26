#!/usr/bin/env wolframscript
(* ::Package:: *)

SetDirectory@ NotebookDirectory[];

(* read in the reactions*)
d = Import["./data/Selected_Data_withPubdate.json", "RawJSON"];

(* select only reactions containing precursors which appear 5 or more times, and group by targets *)
allPrecursors = Counts@ Flatten@ Lookup["Precursors"]@ d;
allowedPrecursors = KeySort@ Select[GreaterEqualThan[5]]@ allPrecursors;
allowedReactions=Query[Select[ContainsOnly[#Precursors, Keys[allowedPrecursors]]&]]@ d;
(* use KeyMap to extract a single target from the list, JSON only allows for strings as dictionary keys*)
allowedTargets=Map[DeleteDuplicatesBy[Sort]]@ KeyMap[First]@ 
	Query[GroupBy["Target"], All,"Precursors"]@ allowedReactions;

(* export target and precursor dictionaries *)
Export["./data/targets.json", allowedTargets, "RawJSON", "Compact"->1];
Export["./data/precursors.json", allowedPrecursors];

(* generate 5-fold CV splits *)
SeedRandom[2024];
shuffledTargets = RandomSample@ Normal@ allowedTargets;

Clear[generateCVSplits]
generateCVSplits[data_, iteration_Integer, folds_:5]:= With[
	{splits=Partition[data, UpTo[Ceiling[Length[data]/folds]]],
	file= StringTemplate["./data/cross_validation/random_cv``.json"]@iteration},
	Export[file, #, "JSON", "Compact"->3]&@
		AssociationThread[
			{"train", "test"}->({Join@@#[[2]], #[[1,1]]}&@ TakeDrop[splits, {iteration}])]]

generateCVSplits[shuffledTargets, #]&/@ Range[5];
