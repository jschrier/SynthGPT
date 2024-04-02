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
