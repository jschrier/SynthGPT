#!/usr/bin/env wolframscript
(* ::Package:: *)

SetDirectory@NotebookDirectory[];
<<"./src/combined.wl"

createSubbatches[piece_:"cv1", batchSize_:100]:= With[
	{both = mergeResults["top5_random_"<>piece<>".json", "./results"]},
	MapIndexed[
		Export[
			"./data/combined/"<>piece<>"/batch"<>IntegerString[#2[[1]], 10, 2]<>".json", 
			#1, "Compact"->2]&,
		Partition[both, UpTo[batchSize]]]]
		
createSubbatches/@{"cv1", "cv2", "cv3", "cv4", "cv5"}

