#!/bin/sh
#   Copyright (C) 2012 University of Oxford
#
#   Part of FSL - FMRIB's Software Library
#   http://www.fmrib.ox.ac.uk/fsl
#   fsl@fmrib.ox.ac.uk
#   
#   Developed at FMRIB (Oxford Centre for Functional Magnetic Resonance
#   Imaging of the Brain), Department of Clinical Neurology, Oxford
#   University, Oxford, UK
#   
#   
#   LICENCE
#   
#   FMRIB Software Library, Release 5.0 (c) 2012, The University of
#   Oxford (the "Software")
#   
#   The Software remains the property of the University of Oxford ("the
#   University").
#   
#   The Software is distributed "AS IS" under this Licence solely for
#   non-commercial use in the hope that it will be useful, but in order
#   that the University as a charitable foundation protects its assets for
#   the benefit of its educational and research purposes, the University
#   makes clear that no condition is made or to be implied, nor is any
#   warranty given or to be implied, as to the accuracy of the Software,
#   or that it will be suitable for any particular purpose or for use
#   under any specific conditions. Furthermore, the University disclaims
#   all responsibility for the use which is made of the Software. It
#   further disclaims any liability for the outcomes arising from using
#   the Software.
#   
#   The Licensee agrees to indemnify the University and hold the
#   University harmless from and against any and all claims, damages and
#   liabilities asserted by third parties (including claims for
#   negligence) which arise directly or indirectly from the use of the
#   Software or the sale of any products based on the Software.
#   
#   No part of the Software may be reproduced, modified, transmitted or
#   transferred in any form or by any means, electronic or mechanical,
#   without the express permission of the University. The permission of
#   the University is not required if the said reproduction, modification,
#   transmission or transference is done without financial return, the
#   conditions of this Licence are imposed upon the receiver of the
#   product, and all original and amended source code is included in any
#   transmitted product. You may be held legally responsible for any
#   copyright infringement that is caused or encouraged by your failure to
#   abide by these terms and conditions.
#   
#   You are not permitted under this Licence to use this Software
#   commercially. Use for which any financial return is received shall be
#   defined as commercial use, and includes (1) integration of all or part
#   of the source code or the Software into a product for sale or license
#   by or on behalf of Licensee to third parties or (2) use of the
#   Software or any derivative of it for research with the final aim of
#   developing software products for sale or license to a third party or
#   (3) use of the Software or any derivative of it for research with the
#   final aim of developing non-software products for sale or license to a
#   third party, or (4) use of the Software to provide any service to an
#   external organisation for which payment is received. If you are
#   interested in using the Software commercially, please contact Isis
#   Innovation Limited ("Isis"), the technology transfer company of the
#   University, to negotiate a licence. Contact details are:
#   innovation@isis.ox.ac.uk quoting reference DE/9564.
export LC_ALL=C
if [ $# -le 3 ] ; then
  echo "$0 <randomise options>"
  echo ""
  echo "Actual number of permutations performed may differ slightly from those 
  requested due to tasking an equal number of permutations per fragment."
  echo ""
  echo "Caution: if a design has less unique permutations than those requested, 
  the defragment script will not work correctly!"
  exit 1
fi

RANDOMISE_OUTPUT=`$FSLDIR/bin/randomise $@ -Q`
if [ $? != 0 ] ; then 
  echo "ERROR: Randomise could not succesfully initialise with the command line given. Submission aborted."
  exit 1
fi 

PERMS=`echo $RANDOMISE_OUTPUT | awk '{print $1}'`
CONTRASTS=`echo $RANDOMISE_OUTPUT | awk '{print $2}'`
ROOTNAME=`echo $RANDOMISE_OUTPUT | awk '{print $3}'`
BASENAME=`basename $ROOTNAME`
DIRNAME=`dirname $ROOTNAME`

mkdir -p ${DIRNAME}/${BASENAME}_logs

PERMS_PER_SLOT=`echo $RANDOMISE_OUTPUT | awk '{print $4}'`
if [ x${REQUESTED_TIME} = 'x' ] ; then
    REQUESTED_TIME=30
fi

SLOTS_PER_CONTRAST=`expr $PERMS / $PERMS_PER_SLOT`

if [ $SLOTS_PER_CONTRAST -lt 1 ] ; then
    SLOTS_PER_CONTRAST=1
fi

PERMS_PER_CONTRAST=`expr $PERMS_PER_SLOT \* $SLOTS_PER_CONTRAST`

REQUESTED_SLOTS=`expr $CONTRASTS \* $SLOTS_PER_CONTRAST`
      
CORRECTED_PERMS=`expr $PERMS_PER_CONTRAST - $SLOTS_PER_CONTRAST`
CORRECTED_PERMS=`expr $CORRECTED_PERMS + 1`

echo "Generating" $REQUESTED_SLOTS "fragments for " $CONTRASTS " contrasts with " $PERMS_PER_SLOT "permutations per fragment. Allocating" ${REQUESTED_TIME} "minutes per fragment." 
echo "The total number of permutations per contrast will be" $PERMS_PER_CONTRAST "."

#stage 1:
CURRENT_SEED=1
if [ -e ${DIRNAME}/${BASENAME}.generate ] ; then
  /bin/rm ${DIRNAME}/${BASENAME}.generate
fi
while [ $CURRENT_SEED -le $SLOTS_PER_CONTRAST ] ; do
  SLEEPTIME=`expr 1 \* $CURRENT_SEED`
  CURRENT_CONTRAST=1
  while [ $CURRENT_CONTRAST -le $CONTRASTS ] ; do
      echo "FSLOUTPUTTYPE=NIFTI_GZ; sleep $SLEEPTIME ; ${FSLDIR}/bin/randomise $@ -n $PERMS_PER_SLOT -o ${ROOTNAME}_SEED${CURRENT_SEED} --seed=$CURRENT_SEED --skipTo=$CURRENT_CONTRAST" >> ${DIRNAME}/${BASENAME}.generate
      CURRENT_CONTRAST=`expr $CURRENT_CONTRAST + 1`
  done
  echo done $CURRENT_SEED
  CURRENT_SEED=`expr $CURRENT_SEED + 1`
done
chmod a+x ${DIRNAME}/${BASENAME}.generate
GENERATE_ID=`$FSLDIR/bin/fsl_sub -T ${REQUESTED_TIME} -N ${BASENAME}.generate -l ${DIRNAME}/${BASENAME}_logs/ -t ${DIRNAME}/${BASENAME}.generate` 

#stage2:
cat <<combineScript > ${DIRNAME}/${BASENAME}.defragment
#!/bin/sh
echo "Merging stat images"
for FIRSTSEED in \`imglob -extension ${ROOTNAME}_SEED1_*_p_* ${ROOTNAME}_SEED1_*_corrp_*\` ; do 
  ADDCOMMAND=""
  ACTIVESEED=1
  if [ -e \$FIRSTSEED ] ; then
    while [ \$ACTIVESEED -le $SLOTS_PER_CONTRAST ] ; do
      ADDCOMMAND=\`echo \$ADDCOMMAND -add \${FIRSTSEED/_SEED1_/_SEED\${ACTIVESEED}_}\`
      ACTIVESEED=\`expr \$ACTIVESEED + 1\`
    done
    ADDCOMMAND=\${ADDCOMMAND#-add}
    echo \$ADDCOMMAND
    \$FSLDIR/bin/fslmaths \$ADDCOMMAND -mul $PERMS_PER_SLOT -div $CORRECTED_PERMS \${FIRSTSEED/_SEED1/}
  fi
done

echo "Merging text files"
for FIRSTSEED in ${ROOTNAME}_SEED1_*perm_*.txt ${ROOTNAME}_SEED1_*_p_*.txt ${ROOTNAME}_SEED1_*_corrp_*.txt ; do 
  ACTIVESEED=1
  if [ -e \$FIRSTSEED ] ; then
    while [ \$ACTIVESEED -le $SLOTS_PER_CONTRAST ] ; do
      if [ \$ACTIVESEED -eq 1 ] ; then
         cat \${FIRSTSEED/_SEED1_/_SEED\${ACTIVESEED}_} >> \${FIRSTSEED/_SEED1/}
      else
         tail -n +2 \${FIRSTSEED/_SEED1_/_SEED\${ACTIVESEED}_} >> \${FIRSTSEED/_SEED1/}
      fi 
      ACTIVESEED=\`expr \$ACTIVESEED + 1\`
    done
  fi
done

echo "Renaming raw stats"
for TYPE in _ _tfce_ ; do
  for FIRSTSEED in \`imglob -extension ${ROOTNAME}_SEED1\${TYPE}tstat* ${ROOTNAME}_SEED1\${TYPE}fstat*\` ; do 
    if [ -e \$FIRSTSEED ] ; then
      cp \$FIRSTSEED \${FIRSTSEED/_SEED1/}
    fi
  done
done

ACTIVESEED=1
while [ \$ACTIVESEED -le $SLOTS_PER_CONTRAST ] ; do
  rm -rf ${ROOTNAME}_SEED\${ACTIVESEED}*_p_*
  rm -rf ${ROOTNAME}_SEED\${ACTIVESEED}*_corrp_*
  rm -rf \`imglob -extensions ${ROOTNAME}_SEED\${ACTIVESEED}*stat????\`
  rm -rf \`imglob -extensions ${ROOTNAME}_SEED\${ACTIVESEED}*stat???\`
  rm -rf \`imglob -extensions ${ROOTNAME}_SEED\${ACTIVESEED}*stat??\`
  rm -rf \`imglob -extensions ${ROOTNAME}_SEED\${ACTIVESEED}*stat?\`
  rm -rf ${ROOTNAME}_SEED\${ACTIVESEED}_*perm_*.txt ${ROOTNAME}_SEED\${ACTIVESEED}_*_p_*.txt ${ROOTNAME}_SEED\${ACTIVESEED}_*_corrp_*.txt

  ACTIVESEED=\`expr \$ACTIVESEED + 1\`
done
 
echo "Done"
combineScript
chmod +x ${DIRNAME}/${BASENAME}.defragment

DEFRAGMENT_TIME=20
if [ ${REQUESTED_SLOTS} -ge 150 ] ; then
  DEFRAGMENT_TIME=40
fi

echo "fsl_sub -j $GENERATE_ID -T ${DEFRAGMENT_TIME} -l ${DIRNAME}/${BASENAME}_logs/ -N ${BASENAME}.defragment ${DIRNAME}/${BASENAME}.defragment"
