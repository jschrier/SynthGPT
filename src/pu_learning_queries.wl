(* ::Package:: *)

(* import necessary library *)
Import["https://raw.githubusercontent.com/antononcube/MathematicaForPrediction/master/Misc/OpenAIRequest.m"]

(* perform a PU-learning prediction of synthesizability *)
puPrediction[target_->answer_, model_:"gpt-3.5-turbo", temperature_:0]:= With[
	{response = extractProbabilities@ synthesizabilityRequest[target, model, temperature]},
	With[
		{predicted = First@ Keys@ TakeLargest[1]@ response},
		<|"correctQ" -> StringMatchQ[predicted, answer, IgnoreCase->True],
		"target" -> target,
		"prediction" -> predicted,
		"answer" -> answer,
		"output" -> ExportString[response, "JSON", "Compact"->True],
		"p(P)" -> Lookup[response, "P", 0],
		"p(U)" -> Lookup[response, "U", 0]|>]]


(* extract the log-prob information returned by OpenAI and convert to probability *)
extractProbabilities[response_Association]:= With[
	{topLogprobs=response[["choices", 1, "logprobs","content", 1, "top_logprobs"]] },
	Map[Exp, AssociationThread@@ Transpose@ Lookup[{"token", "logprob"}]@ topLogprobs]]

(* 
make the underlying API call; we have to do this somewhat manually, as the current
Wolfram API wrapper does not support LogProbs in chat API; 
see: https://mathematica.stackexchange.com/questions/301338/openai-serviceconnect-for-chat-completion-api-does-not-properly-implement-log 
*)
synthesizabilityRequest[target_, model_:"gpt-3.5-turbo", temperature_:0]:= OpenAIRequest[
	{"v1", "chat", "completions"},
	<|"model" -> model,
	"messages"->{
		<|"role"->"system", "content"->"You are an expert inorganic chemist.  Determine if the following compound is likely to be synthesizable based on its composition, answering only \"P\" (for positive or possible) and \"U\" (for unknown or unlikely)."|>,
		<|"role"->"user", "content"->"Is this inorganic compound synthesizable? "<>target|>},
	"temperature"->temperature,
	"max_tokens"->2,
	"logprobs"->True,
	"top_logprobs"->3|>]
	
(* helper function for evaluating a batch input test files *)
evaluatePUPrediction[
	model_:"gpt-3.5-turbo", 
	temperature_:0, 
	outputPath_String:"./results_MP/gpt-3.5"][
	inputFile_?FileExistsQ]:= With[
	{outputFile = FileNameJoin@ 
		Append[FileNameSplit[outputPath], #]&@ #<>".json"&@ FileBaseName[inputFile],
	results = ParallelMap[
				puPrediction[#, model, temperature]&,
				Import[inputFile], 
				DistributedContexts->"OpenAIRequest`",
				ProgressReporting->True ],
	metadata = <|"model" -> model,
				"temperature"->temperature,
				"datasource" -> inputFile,
				"date" -> DateString["ISODateTime"],
				"notes" -> "t.b.d"|>},
	Export[outputFile, <|"metadata"->metadata, "results"->results|>, "Compact"->2];]


(*** define functions for summarization ***)

Clear[summarize]
(* map over files in a particular folder  *)
summarize[folder_?DirectoryQ]:= With[
	{files = FileNames["batch*.json", folder],
	outputFile = folder<>"/summary.json"},
	Export[outputFile, #, "Compact"->2]&@ Map[summarize]@ files;]
	
(* summarize results from one CV run *)
summarize[f_?FileExistsQ]:= With[
	{d = Import[f, "RawJSON"]},
	With[
		{measurements = ClassifierMeasurements[
			Query["results", All, "prediction"]@d, 
			Query["results", All, "answer"]@d]},
			
		<|"dataset" -> Query["metadata", "datasource"]@ d,
		"accuracy" -> measurements["Accuracy"],
		"recall"-> measurements["Recall"->"P"],
		"mcc"->measurements["MatthewsCorrelationCoefficient"->"P"],
		"n_correct" -> Total@ Boole@ Query["results", All, "correctQ"]@ d,
		"n_test" -> Query["results", Length]@ d|>]]

