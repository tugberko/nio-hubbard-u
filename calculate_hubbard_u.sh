#! /bin/bash

#SBATCH —job-name=np-benchmark
#SBATCH --ntasks=1
#SBATCH --time=480:00:00


vasp=/share/apps/vasp/vasp.5.4.4/bin/vasp_std

LANG=en_US
SCRATCHPATH=/scratch/tugberkozdemir

i=4

cat /share/apps/vasp/pot/PAW/LDA/Ni/POTCAR /share/apps/vasp/pot/PAW/LDA/Ni/POTCAR /share/apps/vasp/pot/PAW/LDA/O/POTCAR >> resources/POTCAR.LDA
cat /share/apps/vasp/pot/PAW/PBE/Ni/POTCAR /share/apps/vasp/pot/PAW/PBE/Ni/POTCAR /share/apps/vasp/pot/PAW/PBE/O/POTCAR >> resources/POTCAR.PBE

# flush remains
rm -rf $SCRATCHPATH/hubbard_u/playground
rm -rf $SCRATCHPATH/hubbard_u/storage
rm -rf results-pbe
rm -rf results-lda

mkdir -p $SCRATCHPATH/hubbard_u/playground
mkdir -p $SCRATCHPATH/hubbard_u/storage
mkdir -p results-pbe
mkdir -p results-lda

touch results-pbe/scf
touch results-pbe/non-scf

touch results-lda/scf
touch results-lda/non-scf

echo "$(tput setaf 5)$(tput setab 7)                                      $(tput sgr 0)";
echo "$(tput setaf 5)$(tput setab 7)       _/_/_/    _/_/_/    _/_/_/_/   $(tput sgr 0)";
echo "$(tput setaf 5)$(tput setab 7)      _/    _/  _/    _/  _/          $(tput sgr 0)";
echo "$(tput setaf 5)$(tput setab 7)     _/_/_/    _/_/_/    _/_/_/       $(tput sgr 0)";
echo "$(tput setaf 5)$(tput setab 7)    _/        _/    _/  _/            $(tput sgr 0)";
echo "$(tput setaf 5)$(tput setab 7)   _/        _/_/_/    _/_/_/_/       $(tput sgr 0)";
echo "$(tput setaf 5)$(tput setab 7)                                      $(tput sgr 0)";
echo "$(tput setaf 5)$(tput setab 7)                                      $(tput sgr 0)";


# PBE Groundstate calculation
echo ""
echo "$(tput setaf 7)$(tput setab 7) **  PBE Ground state calculation  ** $(tput sgr 0)"
echo "$(tput setaf 1)$(tput setab 7)     PBE Ground state calculation     $(tput sgr 0)"
echo "$(tput setaf 7)$(tput setab 7) **  PBE Ground state calculation  ** $(tput sgr 0)"
echo ""

cp resources/INCAR.ground_state $SCRATCHPATH/hubbard_u/playground/INCAR
cp resources/KPOINTS $SCRATCHPATH/hubbard_u/playground/KPOINTS
cp resources/POSCAR $SCRATCHPATH/hubbard_u/playground/POSCAR
cp resources/POTCAR.PBE $SCRATCHPATH/hubbard_u/playground/POTCAR

mpirun -np $i -wdir $SCRATCHPATH/hubbard_u/playground $vasp

cp  $SCRATCHPATH/hubbard_u/playground/CHGCAR $SCRATCHPATH/hubbard_u/storage/CHGCAR.0
cp  $SCRATCHPATH/hubbard_u/playground/WAVECAR $SCRATCHPATH/hubbard_u/storage/WAVECAR.0
cp  $SCRATCHPATH/hubbard_u/playground/OUTCAR results-pbe/OUTCAR.0

target=$(awk '/total charge/ { ln = FNR } END { print ln }' results-pbe/OUTCAR.0)
chg=$(awk -v target=$(($target+4)) 'NR==target{print $4;exit}' results-pbe/OUTCAR.0)

echo 0 $chg >> results-pbe/scf
echo 0 $chg >> results-pbe/non-scf


# PBE response calculations
for v in -0.5 -0.4 -0.3 -0.2 -0.1 0.1 0.2 0.3 0.4 0.5
do
  #Non-SCF response
  echo ""
  echo "$(tput setaf 7)$(tput setab 7)** PBE Non-SCF response (V = $v eV) **$(tput sgr 0)"
  echo "$(tput setaf 1)$(tput setab 7)   PBE Non-SCF response (V = $v eV)   $(tput sgr 0)"
  echo "$(tput setaf 7)$(tput setab 7)** PBE Non-SCF response (V = $v eV) **$(tput sgr 0)"
  echo ""

  #flush playground
  rm -rf $SCRATCHPATH/hubbard_u/playground
  mkdir -p $SCRATCHPATH/hubbard_u/playground

  cp resources/INCAR.nscf $SCRATCHPATH/hubbard_u/playground/INCAR
  cp resources/KPOINTS $SCRATCHPATH/hubbard_u/playground/KPOINTS
  cp resources/POSCAR $SCRATCHPATH/hubbard_u/playground/POSCAR
  cp resources/POTCAR.PBE $SCRATCHPATH/hubbard_u/playground/POTCAR

  echo "LDAU = .TRUE." >> $SCRATCHPATH/hubbard_u/playground/INCAR
  echo "LDAUTYPE = 3" >> $SCRATCHPATH/hubbard_u/playground/INCAR
  echo "LDAUL = 2 -1 -1" >> $SCRATCHPATH/hubbard_u/playground/INCAR
  echo "LDAUU =  $v 0.00 0.00" >> $SCRATCHPATH/hubbard_u/playground/INCAR
  echo "LDAUJ =  $v 0.00 0.00" >> $SCRATCHPATH/hubbard_u/playground/INCAR

  cp $SCRATCHPATH/hubbard_u/storage/CHGCAR.0 $SCRATCHPATH/hubbard_u/playground/CHGCAR
  cp $SCRATCHPATH/hubbard_u/storage/WAVECAR.0 $SCRATCHPATH/hubbard_u/playground/WAVECAR

  mpirun -np $i -wdir $SCRATCHPATH/hubbard_u/playground $vasp

  cp $SCRATCHPATH/hubbard_u/playground/OUTCAR results-pbe/OUTCAR.nscf.v=$v

  target=$(awk '/total charge/ { ln = FNR } END { print ln }' results-pbe/OUTCAR.nscf.v=$v)
  chg=$(awk -v target=$(($target+4)) 'NR==target{print $4;exit}' results-pbe/OUTCAR.nscf.v=$v)
  echo $v $chg >> results-pbe/non-scf



  #SCF-response
  echo ""
  echo "$(tput setaf 7)$(tput setab 7)** PBE SCF response (V = $v eV) **$(tput sgr 0)"
  echo "$(tput setaf 1)$(tput setab 7)   PBE SCF response (V = $v eV)   $(tput sgr 0)"
  echo "$(tput setaf 7)$(tput setab 7)** PBE SCF response (V = $v eV) **$(tput sgr 0)"
  echo ""

  #flush playground
  rm -rf $SCRATCHPATH/hubbard_u/playground
  mkdir -p $SCRATCHPATH/hubbard_u/playground

  cp resources/INCAR.scf $SCRATCHPATH/hubbard_u/playground/INCAR
  cp resources/KPOINTS $SCRATCHPATH/hubbard_u/playground/KPOINTS
  cp resources/POSCAR $SCRATCHPATH/hubbard_u/playground/POSCAR
  cp resources/POTCAR.PBE $SCRATCHPATH/hubbard_u/playground/POTCAR

  echo "LDAU = .TRUE." >> $SCRATCHPATH/hubbard_u/playground/INCAR
  echo "LDAUTYPE = 3" >> $SCRATCHPATH/hubbard_u/playground/INCAR
  echo "LDAUL = 2 -1 -1" >> $SCRATCHPATH/hubbard_u/playground/INCAR
  echo "LDAUU =  $v 0.00 0.00" >> $SCRATCHPATH/hubbard_u/playground/INCAR
  echo "LDAUJ =  $v 0.00 0.00" >> $SCRATCHPATH/hubbard_u/playground/INCAR

  cp $SCRATCHPATH/hubbard_u/storage/CHGCAR.0 $SCRATCHPATH/hubbard_u/playground/CHGCAR
  cp $SCRATCHPATH/hubbard_u/storage/WAVECAR.0 $SCRATCHPATH/hubbard_u/playground/WAVECAR

  mpirun -np $i -wdir $SCRATCHPATH/hubbard_u/playground $vasp

  cp $SCRATCHPATH/hubbard_u/playground/OUTCAR results-pbe/OUTCAR.scf.v=$v

  target=$(awk '/total charge/ { ln = FNR } END { print ln }' results-pbe/OUTCAR.scf.v=$v)
  chg=$(awk -v target=$(($target+4)) 'NR==target{print $4;exit}' results-pbe/OUTCAR.scf.v=$v)
  echo $v $chg >> results-pbe/scf

done




echo "$(tput setaf 5)                                      $(tput sgr 0)";
echo "$(tput setaf 5)        _/        _/_/_/      _/_/    $(tput sgr 0)";
echo "$(tput setaf 5)       _/        _/    _/  _/    _/   $(tput sgr 0)";
echo "$(tput setaf 5)      _/        _/    _/  _/_/_/_/    $(tput sgr 0)";
echo "$(tput setaf 5)     _/        _/    _/  _/    _/     $(tput sgr 0)";
echo "$(tput setaf 5)    _/_/_/_/  _/_/_/    _/    _/      $(tput sgr 0)";
echo "$(tput setaf 5)                                      $(tput sgr 0)";
echo "$(tput setaf 5)                                      $(tput sgr 0)";

rm -rf $SCRATCHPATH/hubbard_u/playground
rm -rf $SCRATCHPATH/hubbard_u/storage

mkdir -p $SCRATCHPATH/hubbard_u/playground
mkdir -p $SCRATCHPATH/hubbard_u/storage


# LDA Groundstate calculation
echo ""
echo "$(tput setaf 7)$(tput setab 7)** LDA Ground state calculation **$(tput sgr 0)"
echo "$(tput setaf 1)$(tput setab 7)   LDA Ground state calculation   $(tput sgr 0)"
echo "$(tput setaf 7)$(tput setab 7)** LDA Ground state calculation **$(tput sgr 0)"
echo ""

cp resources/INCAR.ground_state $SCRATCHPATH/hubbard_u/playground/INCAR
cp resources/KPOINTS $SCRATCHPATH/hubbard_u/playground/KPOINTS
cp resources/POSCAR $SCRATCHPATH/hubbard_u/playground/POSCAR
cp resources/POTCAR.LDA $SCRATCHPATH/hubbard_u/playground/POTCAR

mpirun -np $i -wdir $SCRATCHPATH/hubbard_u/playground $vasp

cp  $SCRATCHPATH/hubbard_u/playground/CHGCAR $SCRATCHPATH/hubbard_u/storage/CHGCAR.0
cp  $SCRATCHPATH/hubbard_u/playground/WAVECAR $SCRATCHPATH/hubbard_u/storage/WAVECAR.0
cp  $SCRATCHPATH/hubbard_u/playground/OUTCAR results-lda/OUTCAR.0

target=$(awk '/total charge/ { ln = FNR } END { print ln }' results-lda/OUTCAR.0)
chg=$(awk -v target=$(($target+4)) 'NR==target{print $4;exit}' results-lda/OUTCAR.0)

echo 0 $chg >> results-lda/scf
echo 0 $chg >> results-lda/non-scf

# LDA response calculations
for v in -0.5 -0.4 -0.3 -0.2 -0.1 0.1 0.2 0.3 0.4 0.5
do
  #Non-SCF response
  echo ""
  echo "$(tput setaf 7)$(tput setab 7)** LDA Non-SCF response (V = $v eV) **$(tput sgr 0)"
  echo "$(tput setaf 1)$(tput setab 7)   LDA Non-SCF response (V = $v eV)   $(tput sgr 0)"
  echo "$(tput setaf 7)$(tput setab 7)** LDA Non-SCF response (V = $v eV) **$(tput sgr 0)"
  echo ""

  #flush playground
  rm -rf $SCRATCHPATH/hubbard_u/playground
  mkdir -p $SCRATCHPATH/hubbard_u/playground

  cp resources/INCAR.nscf $SCRATCHPATH/hubbard_u/playground/INCAR
  cp resources/KPOINTS $SCRATCHPATH/hubbard_u/playground/KPOINTS
  cp resources/POSCAR $SCRATCHPATH/hubbard_u/playground/POSCAR
  cp resources/POTCAR.LDA $SCRATCHPATH/hubbard_u/playground/POTCAR

  echo "LDAU = .TRUE." >> $SCRATCHPATH/hubbard_u/playground/INCAR
  echo "LDAUTYPE = 3" >> $SCRATCHPATH/hubbard_u/playground/INCAR
  echo "LDAUL = 2 -1 -1" >> $SCRATCHPATH/hubbard_u/playground/INCAR
  echo "LDAUU =  $v 0.00 0.00" >> $SCRATCHPATH/hubbard_u/playground/INCAR
  echo "LDAUJ =  $v 0.00 0.00" >> $SCRATCHPATH/hubbard_u/playground/INCAR

  cp $SCRATCHPATH/hubbard_u/storage/CHGCAR.0 $SCRATCHPATH/hubbard_u/playground/CHGCAR
  cp $SCRATCHPATH/hubbard_u/storage/WAVECAR.0 $SCRATCHPATH/hubbard_u/playground/WAVECAR

  mpirun -np $i -wdir $SCRATCHPATH/hubbard_u/playground $vasp

  cp $SCRATCHPATH/hubbard_u/playground/OUTCAR results-lda/OUTCAR.nscf.v=$v

  target=$(awk '/total charge/ { ln = FNR } END { print ln }' results-lda/OUTCAR.nscf.v=$v)
  chg=$(awk -v target=$(($target+4)) 'NR==target{print $4;exit}' results-lda/OUTCAR.nscf.v=$v)
  echo $v $chg >> results-lda/non-scf



  #SCF-response
  echo ""
  echo "$(tput setaf 7)$(tput setab 7)** LDA SCF response (V = $v eV) **$(tput sgr 0)"
  echo "$(tput setaf 1)$(tput setab 7)   LDA SCF response (V = $v eV)   $(tput sgr 0)"
  echo "$(tput setaf 7)$(tput setab 7)** LDA SCF response (V = $v eV) **$(tput sgr 0)"
  echo ""

  #flush playground
  rm -rf $SCRATCHPATH/hubbard_u/playground
  mkdir -p $SCRATCHPATH/hubbard_u/playground

  cp resources/INCAR.scf $SCRATCHPATH/hubbard_u/playground/INCAR
  cp resources/KPOINTS $SCRATCHPATH/hubbard_u/playground/KPOINTS
  cp resources/POSCAR $SCRATCHPATH/hubbard_u/playground/POSCAR
  cp resources/POTCAR.LDA $SCRATCHPATH/hubbard_u/playground/POTCAR

  echo "LDAU = .TRUE." >> $SCRATCHPATH/hubbard_u/playground/INCAR
  echo "LDAUTYPE = 3" >> $SCRATCHPATH/hubbard_u/playground/INCAR
  echo "LDAUL = 2 -1 -1" >> $SCRATCHPATH/hubbard_u/playground/INCAR
  echo "LDAUU =  $v 0.00 0.00" >> $SCRATCHPATH/hubbard_u/playground/INCAR
  echo "LDAUJ =  $v 0.00 0.00" >> $SCRATCHPATH/hubbard_u/playground/INCAR

  cp $SCRATCHPATH/hubbard_u/storage/CHGCAR.0 $SCRATCHPATH/hubbard_u/playground/CHGCAR
  cp $SCRATCHPATH/hubbard_u/storage/WAVECAR.0 $SCRATCHPATH/hubbard_u/playground/WAVECAR

  mpirun -np $i -wdir $SCRATCHPATH/hubbard_u/playground $vasp

  cp $SCRATCHPATH/hubbard_u/playground/OUTCAR results-lda/OUTCAR.scf.v=$v

  target=$(awk '/total charge/ { ln = FNR } END { print ln }' results-lda/OUTCAR.scf.v=$v)
  chg=$(awk -v target=$(($target+4)) 'NR==target{print $4;exit}' results-lda/OUTCAR.scf.v=$v)
  echo $v $chg >> results-lda/scf

done
