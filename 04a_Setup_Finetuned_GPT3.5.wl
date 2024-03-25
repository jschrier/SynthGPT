(* ::Package:: *)

(* generate JSON-LD files to upload to the OpenAI website *)

fineTuneSplit[f_?FileExistsQ]:= Module[
	{train, test, validate, finetune, newFile},
	newFile = StringReplace[{"data/"->"data/finetuning/", "_random"->"", ".json"->""}]@ f;
	{train,test} = Values@ Import[f];
	{validate, finetune} = TakeDrop[train, Floor[Length[train]/5]];
	generateFineTuningData[newFile<>"_train.jsonl", finetune];
	generateFineTuningData[newFile<>"_validate.jsonl", validate];
]


SetDirectory@NotebookDirectory[];
<<"./src/fine_tuning.wl"

FileSystemMap[fineTuneSplit, "./data/", FileNameForms->"cv*.json"];

(* 

after this is complete, follow the instructions on 
https://platform.openai.com/docs/guides/fine-tuning 
to upload the resulting files and have OpenAI perform the finetuning 
with default hyperparameters 

As of March 2024, fine-tuning these datasets costs about $11 USD and takes 90 minutes.
 *)
