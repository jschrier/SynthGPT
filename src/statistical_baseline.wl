(* ::Package:: *)

(* define source elements following Kim et al. Chem. Sci 2024 doi:10.1039/D3SC03538G *)  
nonSourceElements = ElementData/@{1, 2, 6, 7, 8, "Halogen", "NobleGas"}//Flatten;
sourceElements = Complement[ElementData[], nonSourceElements];

(*remove stoichiometric information from a formula string, 
  because ChemicalFormula only accepts integer amounts, and return a list of
  the elements as Entity["Element", _] formats *)
hasElements[formula_String]:= With[
	{elementsOnly = ChemicalFormula@ StringReplace[NumberString->""]@ formula},
	Keys@ elementsOnly["ElementCounts"]]

(* overload to apply to a list of formulas, e.g., a set of precursors *)
hasElements[formulas_List]:= DeleteDuplicates@ Flatten@ Map[hasElements, formulas]

(* return a list of what source elements are present in the targets *)
sourceElementsInTargets[allowedReactions_List]:= With[
	{targetElements = hasElements@ Flatten@ Lookup["Target"]@ allowedReactions},
	Intersection[sourceElements, targetElements]]
	
sourceElementsInTargets[targets_Association]:=With[
	{targetElements = hasElements@ Keys[targets]},
	Intersection[sourceElements, targetElements]]	

(* return true/false if the element is present in the formula *)
containsElementQ[element_Entity][formula_String]:= 
	ContainsAny[{element}]@ hasElements[formula]

(*create an empirical frequency distribution of each precursor element*)
elementDistribution[precursors_Association][element_Entity]:=
	CategoricalDistribution@ KeySelect[containsElementQ[element]]@ precursors
	
(* generate an association of eEntity["Element"] -> precursor CategoricalDistribution 
   based on the frequencies in the allowedReactions list*)
sourceElementWeights[allowedReactions_List]:= With[
	{targetSourceElements = sourceElementsInTargets[allowedReactions],
	allowedPrecursors = Counts@ Flatten@ Lookup["Precursors"]@ allowedReactions},
	AssociationMap[ 
		elementDistribution[allowedPrecursors], 
		targetSourceElements]]	
		
(* sampling the distribution up to k times *)
samplePrecursors[sourceElementWeights_Association, k_Integer:1][target_String]:=
	Transpose@ Map[RandomVariate[#,k]&]@ 
		Lookup[sourceElementWeights, hasElements[target], Nothing]

(* example *)
(*
sourceWeights = sourceElementWeights[allowedReactions];
samplePrecursors[sourceWeights, 5]["Li4Ti5O12"]
*)


(* evaluate a statistical baseline by choosing k precursors,
    whose source elements are contained in the target, from the empirical weights,
    and see if it matches any of the precursors lists *)

evaluateBaselinePrediction[
	sourceElementWeights_Association, k_Integer:1][target_String->precursors_List]:=
	With[
	{prediction = samplePrecursors[sourceElementWeights, k]@ target},
	<|"correctQ" -> precursorMatchQ[precursors, prediction],
	  "target" -> target,
	  "answer" -> precursors,
	  "prediction" -> prediction |>]
	
	
(* overloaded version for an input cross validation file *)
evaluateBaselinePrediction[
	weights_Association, 
	k_Integer:1,
	outputPath_:{".", "results", "statistical_baseline"}][
	inputFile_?FileExistsQ]:= With[
	{outputFile = FileNameJoin@ Append[outputPath, #]&@ 
					StringTemplate["top``_``"][k, FileNameTake[inputFile]],
					
	results = ParallelMap[
		evaluateBaselinePrediction[weights, k], 
		Lookup["test"]@ Import[inputFile] ],

	metadata = <|"model" -> "statistical_baseline",
				"datasource" -> inputFile,
				"date" -> DateString["ISODateTime"],
				"notes" -> "t.b.d"|>},
				
	Export[outputFile, <|"metadata"-> metadata, "results"->results|>, "Compact"->2];]


