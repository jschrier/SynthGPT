(* ::Package:: *)


(* Take an input string of the form A <- B and return B *)
productStrings[rxn_String]:= 
	Flatten@StringReplace[Longest[StartOfString~~__~~" <- "]->""]@ StringSplit[rxn,"\n"..]

(* take an input string A + B + C and return list {A, B, C} *)
precursorList[rxn_String]:= 
	Map[StringReplace[Whitespace->""]]@ StringSplit[#, " + "]&@ productStrings[rxn]

(* extract precursor list from last chat session message*)
precursorList[chat_ChatObject]:=
	precursorList@ Lookup["Content"]@ Last@ chat["Messages"]

(* test of a given prediction matches*)
singlePredictionMatchQ[actual_List][predicted_List]:=
	AnyTrue[ContainsExactly[predicted]]@ actual

(* check if any of the predicted list of precursors is a match*)
precursorMatchQ[actual_List,predicted_List]:=
	AnyTrue[singlePredictionMatchQ[actual]]@ predicted

(* overloaded versuion which takes a ChatObject as input *)
precursorMatchQ[actual_List,prediction_ChatObject]:=
	precursorMatchQ[actual, precursorList[prediction]]


