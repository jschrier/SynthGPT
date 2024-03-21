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

(* provide a filename and a list of examples to generate a jsonLD-style file *)
generateFineTuningData[filename_, examples_]:=
	Export[filename, #, "Text"]&@ StringRiffle[#,"\n"]&@ Map[formatExample]@ examples

