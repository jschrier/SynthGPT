(* ::Package:: *)

(*** functions for fine-tuning GPT-3.5 models **)

formatResponse[target_String, precursors_List]:=
	StringTemplate["`` <- ``"][target, StringRiffle[precursors," + "]]

(* create a single training example with one user/assistant interaction *)
openAIFineTuneMessage[user_String, assistant_String]:=
	ExportString[#, "JSON", "Compact"->True]&@
		<|"messages"->{
			<|"role"->"user", "content"->user|>,
			<|"role"->"assistant", "content"->assistant|>}|>

(* create a training example if there is only one recipe provided *)
formatExample[target_String->{precursors_List}]:= With[
	{user = "synthesize "<>target,
	assistant = formatResponse[target,precursors]},
	openAIFineTuneMessage[user, assistant]]

(* create a training example with multiple synthesis plans *)
(* the idea is that this should teach both the probabilities how to handle multiple requests *)
formatExample[target_String->multiplePrecursors_List]:= With[
	{userMessageTemplate = StringTemplate["provide `` synthesis plans for target: ``"],
	 nRecipes = Length[multiplePrecursors],
	 assistant = StringRiffle[#, "\n"]&@ Map[formatResponse[target, #]&]@ multiplePrecursors},
	openAIFineTuneMessage[userMessageTemplate[nRecipes, target], assistant]]

(* formatting for PU learning *)
formatExample[target_String->label_String]:=With[
(*	{phrases={
		StringTemplate["Is the following inorganic compound synthesizable? ``"],
		StringTemplate["Is the inorganic compound `` synthesizable?"],
		StringTemplate["Is it likely that the compound `` is synthesizable?"],
		StringTemplate["Is it likely that the following compound can be made? ``"],
		StringTemplate["Can the compound `` be made?"],
		StringTemplate["Can the following compound be made? ``"]}}
		
	openAIFineTuneMessage[RandomChoice[phrases][target], label]*)
	{prompt = StringTemplate["You are an expert inorganic chemist.  Determine if the following compound is likely to be synthesizable based on its composition, answering only \"P\" (for positive or possible) and \"U\" (for unknown or unlikely): ``"]},
	openAIFineTuneMessage[prompt[target], label]
	]
	

(* 
provide a filename and a list of examples to generate a JSONL-style file
see specification at: https://jsonlines.org 
 *)
generateFineTuningData[filename_, examples_]:=
	Export[filename, #, "Text"]&@ StringRiffle[#,"\n"]&@ Map[formatExample]@ examples

