(* ::Package:: *)

(*remove stoichiometric information from a formula string, 
  because ChemicalFormula only accepts integer amounts, and return a list of
  the elements as Entity["Element", _] formats *)
hasElements[formula_String]:= With[
	{elementsOnly = ChemicalFormula@ StringReplace[NumberString->""]@ formula},
	Keys@ elementsOnly["ElementCounts"]]

hasElements[formulas_List]:= DeleteDuplicates@ Flatten@ Map[hasElements,formulas]

(* return a list of what source elements---following definitions in Kim et al. Chem. Sci 2024--
   are present in the targets *) 
sourceElementsInTargets[allowedReactions_List]:=With[
	{targetElements = hasElements@ Flatten@ Lookup["Target"]@ allowedReactions,
	(* Define source elements *)
	sourceElements = With[
		{nonSourceElements = ElementData/@{1, 2, 6, 7, 8, "Halogen", "NobleGas"}//Flatten},
		Complement[ElementData[], nonSourceElements]]},
	Intersection[sourceElements, targetElements]]

(*create an empirical frequency distribution of each precursor element*)
elementDistribution[precursors_Association][element_Entity]:=
	CategoricalDistribution@ KeySelect[containsElementQ[element]]@ precursors
	
(* generate an association of eEntity["Element"] -> precursor CategoricalDistribution 
   based on the frequencies in the allowedReactions list*)
sourceElementWeights[allowedReactions_List]:=With[
	{targetSourceElements = sourceElementsInTargets[allowedReactions],
	allowedPrecursors = Counts@ Flatten@ Lookup["Precursors"]@ allowedReactions},
	AssociationMap[ 
		elementDistribution[allowedPrecursors], 
		targetSourceElements]]	
		
(* sampling the distribution up to k times *)
samplePrecursors[sourceElementWeights_Association, k_Integer:1][target_String]:=
	Transpose@ Map[RandomVariate[#,k]&]@ 
		Lookup[sourceElementWeights, hasElements[target], Nothing]

(* demo *)
(*
sourceWeights = sourceElementWeights[allowedReactions];
samplePrecursors[sourceWeights, 5]["Li4Ti5O12"]
*)


(* evaluate a statistical baseline by choosing k precursors,
    whose source elements are contained in the target, from the empirical weights,
    and see if it matches any of the precursors lists *)
evaluateBaselinePrediction[
	sourceElementWeights_Association, k_Integer:1][{target_String}->precursors_List]:=
	With[
	{prediction = samplePrecursors[sourceElementWeights, k]@ target},
	<|"correct" -> precursorMatchQ[precursors, prediction],
	  "input" ->StringTemplate["`` (statistical baseline, k=``)"][target, k],
	  "output" -> prediction |>]



