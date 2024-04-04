#!/usr/bin/env wolframscript
(* ::Package:: *)

SetDirectory@ NotebookDirectory[];

(* read in the reactions*)
d = Import["./data_MP/PU_composition_2020.json", "RawJSON"];

(* default settings are 80/20 split with a random shuffle *)
SeedRandom[2024];
d = RandomSample/@ d; (*shuffle train and test*) 
{pTrain, pTest} = TakeDrop[#, Floor[Length[#]*.80]]&@ d["positive"];
{uTrain, uTest} = TakeDrop[#, Floor[Length[#]*.80]]&@ d["unlabeled"];

Export["./data_MP/PU_train_test.json",
	<|"train"-><|"positive"->pTrain, "unlabeled"->uTrain|>,
	  "test"-> <|"positive"->pTest,  "unlabeled"->uTest|>|>]


(* setup data for evaluations;
   it is too slow to evaluate all 78k P+U entries with GPT, 
   so we generate sub-samples with the same proportion as the test set *)
test = With[
	{p = (#->"P")&/@ pTest,
	 u = (#->"U")&/@ uTest},
	RandomSample@ Join[p, u]];

(* these are saved in a binary format for convenience, and folder not synced with Github *)
MapIndexed[
	Export["./data_MP/test_batch/batch"<>IntegerString[First[#2], 10, 2]<>".mx", #1]&,
	Partition[test, UpTo[5000]]]
