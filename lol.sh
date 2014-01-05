#!/bin/bash
# Script used to encrypt a file using a lot of layers
# requires shred and gpg for secure mode, other dependencies are in modules
# Usage: "./lol.sh nameoffiletoencrypt" will encrypt a file and generate a script to decrypt it
# 0.1 Core functions work, but only 3DES_openssl lolmod is properly implemented
# 0.1.1 Implemented dependency check in 3DES_openssl
########################
directory="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
filename=$1
securemode=1 #set to 1 to password protect the key script
if [[ -z "$filename" ]]; then
	echo "Usage is './lol.sh filename'"
	exit;
fi

if [ -f $directory/ciphers.txt ]; then
	rm $directory/ciphers.txt # clean cipher list
fi

function f_dependency {
deps_ok=YES
for program in $dependencies
do
	if ! which $program &>/dev/null;  then
		deps_ok=NO
		echo "$program not installed, module $lolmod not loaded"
fi
done
if [ "$deps_ok" = "YES" ]; then
		echo $lolmod >> $directory/ciphers.txt && echo "$lolmod activated"
		echo "All dependencies found, module $lolmod activated"
fi
}

for lolmod in $(ls $directory/lolmod); #load ciphers (each cipher must add itself to the list)
do
	source $directory/lolmod/$lolmod
done

if [ -f $directory/ciphers.txt ]; then
	methods=$(cat $directory/ciphers.txt|wc -l)
else
	echo "No lolmod loaded, Aborting"
	exit;
fi

function f_randpass { # generates a "random" string from /dev/urandom --> this is not optimal!
#  $1 = number of characters; defaults to 32
#  $2 = include special characters; 1 = yes, 0 = no; defaults to 1
[ "$2" == "0" ] && CHAR="[:alnum:]" || CHAR="[:graph:]"
frandom=$(cat /dev/urandom | tr -cd "$CHAR" | head -c ${1:-32})
}

function f_main {
echo "how many rounds of multilayered encryption would you like?"
read rounds
echo "We will now crypt $filename with $methods layers $rounds times"

if [ ! -d $directory/$filename-keys ]; then
	mkdir $directory/$filename-keys
fi

cp $filename $filename.ori #make a backup of file

nlayers=1
layer=1
while [ "$nlayers" -le "$rounds" ]; do # The while only allows to do multiple runs of all layers on file
	for method in $(cat $directory/ciphers.txt);
	do
		echo "Calling f_cypher_$method"
		f_cypher_$method
		layer=$(( $layer + 1 ))
	done
	nlayers=$(( $nlayers + 1 ))
done
#build key
echo "#!/bin/bash" > $directory/$filename-decrypt.sh
for files in $(ls -t $directory/$filename-keys);
do
	cat $directory/$filename-keys/$files >> $directory/$filename-decrypt.sh
done
if [ "$securemode" = "1" ]; then # To secure key script, use:
	echo "eval \"\$(dd if=\$0 bs=1 skip=XX 2>/dev/null|gpg -d 2>/dev/null)\"; exit" > $directory/$filename-decrypt-secure.sh; sed -i s:XX:$(stat -c%s $directory/$filename-decrypt-secure.sh): $directory/$filename-decrypt-secure.sh; gpg -c < $directory/$filename-decrypt.sh >> $directory/$filename-decrypt-secure.sh; chmod +x $directory/$filename-decrypt-secure.sh # thanks to rodolfoap (http://www.commandlinefu.com/commands/view/11985/encrypt-and-password-protect-execution-of-any-bash-script)
	shred -n 15 -u $directory/$filename-decrypt.sh
fi
}
f_main
