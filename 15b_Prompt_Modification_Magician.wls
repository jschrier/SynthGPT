#!/usr/bin/env wolframscript
(* ::Package:: *)

SetDirectory@ NotebookDirectory[];

<<"./src/pu_learning_queries.wl"

(* redefine the SYSTEM message *)
synthesizabilityRequest[target_, model_:"gpt-3.5-turbo", temperature_:0]:= OpenAIRequest[
	{"v1", "chat", "completions"},
	<|"model" -> model,
	"messages"->{
		<|"role"->"system", "content"->"You are a magician.  Determine if the following compound is likely to be synthesizable based on its composition, answering only \"P\" (for positive or possible) and \"U\" (for unknown or unlikely)."|>,
		<|"role"->"user", "content"->"Is this inorganic compound synthesizable? "<>target|>},
	"temperature"->temperature,
	"max_tokens"->2,
	"logprobs"->True,
	"top_logprobs"->3|>]



evaluatePUPrediction["gpt-3.5-turbo-0125", 0,
	 "./results_MP/prompt_modification/magician/gpt-3.5"]@
	"./data_MP/test_batch/batch01.mx"


evaluatePUPrediction["gpt-4-0125-preview", 0, 
	"./results_MP/prompt_modification/magician/gpt-4"]@
	"./data_MP/test_batch/batch01.mx"



evaluatePUPrediction[
	"ft:gpt-3.5-turbo-0125:fordham-university:magician:9WQRoPFD", 0, 
	 "./results_MP/prompt_modification/magician/gpt-3.5_finetune"]@
	"./data_MP/test_batch/batch01.mx"


summarize/@ 
	{"./results_MP/prompt_modification/magician/gpt-3.5", 
	"./results_MP/prompt_modification/magician/gpt-4", 
	"./results_MP/prompt_modification/magician/gpt-3.5_finetune"}
