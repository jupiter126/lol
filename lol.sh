#bash
# Script used to encrypt a file using a lot of layers
# requires shred and gpg for secure mode, other dependencies are in modules
# Usage: "./lol.sh nameoffiletoencrypt" will encrypt a file and generate a script to decrypt it
# 0.1 	Core functions work, but only 3DES_openssl lolmod is properly implemented
# 0.1.1 Implemented dependency check in 3DES_openssl
# 0.2	Implemented Blowfish_mcrypt lolmod
# 0.3	Implemented AES256 with aesutil - with and without base 64 encoding
# 0.3.1	Implemented AES256 with openssl - with and without base 64 encoding
# 0.4	Implemented Cast_256_mcrypt LOKI97_mcrypt Rijndael256_mcrypt Saferplus_mcrypt Serpent_mcrypt Twofish_mcrypt XTEA_mcrypt
# 0.5	Implemented Camelia_256_openssl and ccrypt
# 0.6	Giant Bug-hunt \o/
# 0.7	Added an entropy method with openssl for alternance with urandom
###################### posted code for review: many thanks to Nour, Sepehr and mattcen for their feedback
# Todo:
# - Remove echo from decrypt file and 2>>/dev/null
###
# - Starting with line 24: "$directory", not $directory. Or switch to [[, which doesn't require quoting there.
# - $dependencies should be an array rather than a space-separated list.
# - s/space/IFS/
#######################
# 0.8
# - Be consistent with your test statements. Either use [, or use [[
# - drop into #bash for scripting best practices
# - Use more quotes.
# 0.8 	Added gpg
########################
directory="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
filename="$1"
securemode=1 #set to 1 to password protect the key script
if [[ -z "$filename" ]]; then
	echo "Usage is './lol.sh filename'"
	exit;
fi

if [[ -f $directory/ciphers.txt ]]; then
	rm "$directory/ciphers.txt" # clean cipher list
fi

function f_dependency { # from http://www.snabelb.net/content/bash_support_function_check_dependencies
deps_ok=YES
for program in "$dependencies"
do
	if ! which "$program" &>/dev/null;  then
		deps_ok=NO
		echo "$program not installed, module $lolmod not loaded"
fi
done
if [[ "$deps_ok" = "YES" ]]; then
		echo "$lolmod" >> "$directory/ciphers.txt" && echo "dependencies found - $lolmod activated"
fi
}

for lolmod in $(ls "$directory/lolmod"); #load ciphers (each cipher must add itself to the list)
do
	source "$directory/lolmod/$lolmod"
done

if [[ -f "$directory/ciphers.txt" ]]; then
	methods=$(cat "$directory/ciphers.txt"|wc -l)
else
	echo "No lolmod loaded, Aborting"
	exit;
fi

function f_randpass { # generates a "random" string from /dev/urandom --> this is not optimal!
rem=$(( $layer % 2 ))
if [[ $rem -eq 0 ]]; then
	#  $1 = number of characters; defaults to 32
	#  $2 = include special characters; 1 = yes, 0 = no; defaults to 1
	echo "$layer is even number"
	[[ "$2" == "0" ]] && CHAR="[:alnum:]" || CHAR="[:graph:]"
	frandom=$(cat /dev/urandom | tr -cd "$CHAR" | head -c ${1:-32})
else
	echo "$layer is odd number"
	frandom=$(openssl rand $1|base64)
fi
}

function f_main {
echo "how many rounds of multilayered encryption would you like?"
read rounds
echo "We will now crypt $filename with $methods layers $rounds times"

if [[ ! -d $directory/$filename-keys ]]; then
	mkdir "$directory/$filename-keys"
fi

cp "$filename" "$filename.ori" #make a backup of file

nlayers=1
layer=1
while [[ "$nlayers" -le "$rounds" ]]; do # The while only allows to do multiple runs of all layers on file
	for method in $(cat "$directory/ciphers.txt");
	do
		echo "Calling f_cypher_$method"
		f_cypher_$method
		layer=$(( $layer + 1 ))
	done
	nlayers=$(( $nlayers + 1 ))
done
#build key
echo "#!/bin/bash" > "$directory/$filename-decrypt.sh"
echo "cp $filename $filename.crypted.backup" >> "$directory/$filename-decrypt.sh"
for files in $(ls -t "$directory/$filename-keys");
do
	cat "$directory/$filename-keys/$files" >> "$directory/$filename-decrypt.sh"
	shred -n 8 -u "$directory/$filename-keys/$files"
done
rmdir "$directory/$filename-keys"
if [[ "$securemode" = "1" ]]; then # To secure key script, use:
        echo "eval \"\$(dd if=\$0 bs=1 skip=XX 2>/dev/null|gpg -d 2>/dev/null)\"; exit" > $directory/$filename-decrypt-secure.sh; sed -i s:XX:$(stat -c%s $directory/$filename-decrypt-secure.sh): $directory/$filename-decrypt-secure.sh; gpg -c < $directory/$filename-decrypt.sh >> $directory/$filename-decrypt-secure.sh; chmod +x $directory/$filename-decrypt-secure.sh # thanks to rodolfoap (http://www.commandlinefu.com/commands/view/11985/encrypt-and-password-protect-execution-of-any-bash-script)
	shred -n 8 -u "$directory/$filename-decrypt.sh"
fi
rm "$directory/ciphers.txt"
}
f_main
