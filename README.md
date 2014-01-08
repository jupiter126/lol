lol
===

Lots of Layers - script to crypt a file

The idea behind this script, is that not knowing which vendors/protocols are broken/backdoored/... , Our statistical best bet is to combine as many as possible, resulting in a script key instead of a traditional key. This script key is 
encrypted and password protected with gpg.

Usage: "./lol.sh file"

The script will then ask how many rounds it must run on the file. (1 is more than enough in most cases...) The script will then iterate through all the modules supported by your system and crypt the file once with each module (twice if you 
said 2 at previous question). While crypting the file, each module will generate the necessary line to decrypt the file. Once the iteration is done, lol.sh compiles all decrypt lines in one key-script, and then cripts that key-script with a 
user provided password.

Downsides:

- The encrypted files get much bigger
- It is cpu intensive
- As usual, if your computer is compromised, if somebody steals your key, if you lose it,... it's pretty much game over for your data.

Upsides:
- Only your imagination (and your cpu) limit how much you crypt your data.
