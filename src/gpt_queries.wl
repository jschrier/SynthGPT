(* ::Package:: *)

(* setup a chat session, loading the relevant system prompt, temperature, and model *)
setupChat[systemPrompt_, temperature_:0, model_:"gpt-4-turbo-preview"]:=
	ChatObject[{<|"Role" -> "system", "Content" -> systemPrompt|>}, 
        LLMEvaluator -> <|"Model" -> model, "Temperature" -> temperature|>]
 
(* after you define a session, you can then use it to ask repeated queries, 
thus avoiding the need to re-enter the system prompt each time.  Example:

session = setupChat[prompt];
ChatEvaluate["synthesize Ba2MgGe2O7"]@session; 
*)       
       
(* evaluate a prediction (given a list of known correct answers) *)       
evaluatePrediction[
	session_ChatObject,
	question_TemplateObject:StringTemplate["synthesize ``"]
	][target_String->precursors_List]:= With[
	{prediction = ChatEvaluate[session, question[target], ProgressReporting->False]},
	<|"correct" -> precursorMatchQ[precursors, prediction],
	  "input" -> prediction["Messages"][[-2, "Content"]],
	  "output" -> prediction["Messages"][[-1, "Content"]] |>]

(* top 1 and top 5 predictions *)
evaluateTop1[session_ChatObject][item_]:= 
	evaluatePrediction[session]@ item

evaluateTopN[session_ChatObject, n_Integer][item_]:=With[
	{question = StringTemplate["provide "<>ToString[n]<>" synthesis plans for target: ``"]},
	evaluatePrediction[session, question]@ item]

evaluateTop5[session_ChatObject][item_]:= evaluateTopN[session, 5][item]
