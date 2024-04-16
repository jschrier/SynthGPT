(* ::Package:: *)

(* functions to facilitate combining multiple results *)


mergeResults[e1_Association, e2_Association]:=
	<|"correctQ1"->e1["correctQ"],
	"correctQ2"->e2["correctQ"],
	"correctAny"->(e1["correctQ"]||e2["correctQ"]),
	"correctBoth"->(e1["correctQ"]&&e2["correctQ"]),
	"target"->e1["target"],
	"answer"->e1["answer"],
	"prediction"->(DeleteDuplicates@ Map[Sort]@ Join[e1["prediction"], e2["prediction"]])|>

mergeResults[
	results_String:"top5_random_cv1.json", 
	path_String:"./results/",
	methods_List:{"elemwise","gpt-3.5_finetune_rescore"}]:= With[
	{pastResults = Import[FileNameJoin[{path, #, results}], "RawJSON"]&/@ methods},
	MapThread[ mergeResults, Lookup["results"]@ pastResults]]
	


(* checking returned plans by reformatting the string into lists of precursors *)

(*sometimes the results include asterisks, so catch those too*)
getPlans[message_String?(StringContainsQ["ANSWER:"] )]:= 
	precursorList@ Last[#, "ERROR <- ERROR"]&@ StringCases["ANSWER:\n"|"ANSWER:**\n"~~x__~~EndOfString:>x]@ message

getPlans[chat_ChatObject]:= getPlans@ Query[-1,"Content"]@ chat["Messages"]

(* fallback in case of error *)
getPlans[message_]:= {{"NO ANSWER RETURNED"}}

(* check if the response matches the correct answer *)
plansMatchQ[answer_, response_]:= precursorMatchQ[answer, getPlans[response]]



(* perform the re-evaluation process *)
evaluateCombination[session_ChatObject][entry_Association]:= With[
	{template = StringTemplate["TARGET: ``\nCANDIDATE PLANS:\n``"],
	target = entry["target"],
	candidates =  StringRiffle[entry["prediction"], "\n"," + "]},
	With[
		{response=ChatEvaluate[session, template[target,candidates], ProgressReporting->False]},
		<|"correctQ"->plansMatchQ[entry["answer"], response],
		"target"->target,
		"answer"->entry["answer"],
		"prediction"->getPlans[response],
		"input"->response["Messages"][[-2,"Content"]],
		"output"->response["Messages"][[-1,"Content"]]|>]]

(* overload to take a collection of entries *)
evaluateCombination[session_ChatObject][input_List]:=With[
	{results = ParallelMap[ evaluateCombination[session], input, ProgressReporting->True],
	 metadata = <|"model" -> session["LLMEvaluator"]["Model"]["Name"],
				"temperature"->session["LLMEvaluator"]["Temperature"],
				"datasource" -> "list",
				"date" -> DateString["ISODateTime"],
				"notes" -> "t.b.d"|>},
	<|"metadata"->metadata, "results"->results|>]
	
(* overload to take input and output files *) 
evaluateCombination[session_ChatObject, outputBatchPath_String ][inputFile_?FileExistsQ]:= With[
	{outputFile = FileNameJoin@ Join[FileNameSplit[outputBatchPath], FileNameSplit[inputFile][[-2;;]]],
	output = evaluateCombination[session]@Import[inputFile, "RawJSON"]},
	Export[outputFile, output, "Compact"->2, "ConversionFunction"->ToString]]
	

	
	
	
