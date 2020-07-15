#!/bin/bash

## Jimmy Breen (jimmymbreen@gmail.com)
## 2018-09-10

## Run fastqc and STAR alignment - then quantification
##      - added extra deduplication step for QC

# Sample Specific Params
cpu=16
genome="GRCh37"
base=`pwd`
data=${base}/data

# Indexes and executibles
STARindexDir=star_2-7-3
annotation_file=ref-transcripts.gtf
featureCounts=./featureCounts
gatk=./gatk

# STAR version 2.7.3
STAR=./STAR

# QC, trim and mapping loop over
for FQGZ in ${data}/*R1*.fastq.gz; do

        # Get Sample name for outputs
        SampleName=$(basename ${FQGZ} _R1.fastq.gz)

        # Align data
        mkdir -p ${base}/2_star
        ${STAR} --genomeDir ${STARindexDir} \
                --readFilesIn ${FQGZ} ${FQGZ/R1/R2} \
                --readFilesCommand zcat \
                --outFilterType BySJout \
                --outFilterMismatchNmax 999 \
                --outSAMtype BAM SortedByCoordinate \
                --outFileNamePrefix ${base}/2_star/"${SampleName}"_"${genome}"_ \
                --outSAMattrRGline ID:"${SampleName}" LB:library PL:illumina PU:machine SM:"${genome}" \
                --outSAMmapqUnique 60 \
                --runThreadN ${cpu}

done

# FeatureCounts
mkdir -p ${base}/3_counts
${featureCounts} -a ${annotation_file} -T ${cpu} -s 1 \
        -o ${base}/3_counts/project_allBams_${genome}.geneCounts.tsv \
        ${base}/2_star/*_Aligned.sortedByCoord.out.bam \
        > ${base}/3_counts/${sample_name}.featureCounts.log

cut -f1,7- ${base}/3_counts/project_allBams_${genome}.geneCounts.tsv > ${base}/3_counts/countTable.tsv

