#!/bin/sh
# apply color to part of hexdump output
# Usage: hexdump -C file | apply-color fg-color bg-color start-byte [length=4]
# where colors are number 1-255, start-byte and length could be decimal or hex
if [ $# -lt 2 ]; then
    echo "Error! Too few arguments";
    exit 1;
fi;

# set variables
fgcolor=$1;
bgcolor=$2;
sbyte=$3;
length=4;
bgcmd="\e[48;5;@@@m"
fgcmd="\e[38;5;@@@m"
offcmd="\e[0m"
if [ $# -ge 4 ]; then
    length=$4;
fi;

# source all necessary scripts
source ./apply-func.sh

# convert inputs to hexadecimal form
tohex $length;
length=$tohex;
tohex $sbyte;
sbyte=$tohex;

linestart=$(getlinecaption $sbyte);
lspattern="^$linestart\s\s.*$"
clr=${fgcmd//@@@/$fgcolor}${bgcmd//@@@/$bgcolor}
cmdlinestream $sbyte $length;
cmdstream=$(echo $cmdlinestream | sed 's/:/\n/g'); 
# FIXME: find a way without to replace without a subshell like ${var//:/\n} ?
iterator=1;
enabler=0;
streamlng=$(echo "$cmdstream" | wc -l);
while read -r line; do
    if [[ $line =~ $lspattern ]]; then
        enabler=1;
        hextobc $sbyte;
        offset=$(echo "obase=10;ibase=16;$hextobc % 10" | bc);
        lng=$(echo "$cmdstream" | sed "${iterator}q;d");
        colorbytes "$line" $fgcolor $bgcolor $offset $lng;
        offset=0;
    elif [ $enabler -eq 1 ]; then
        if [ "$line" == "*" ]; then
            echo "$line";
            enabler=0;
            continue;
        fi;
        lng=$(echo "$cmdstream" | sed "${iterator}q;d");
        colorbytes "$line" $fgcolor $bgcolor $offset $lng;
    else
        echo "$line";
    fi;

    # if found line, process few next lines
    if [ $enabler -eq 1 ]; then
        let iterator++;
    fi;

    # if end of command stream, disable
    if [[ $enabler -eq 1 && $iterator -gt $streamlng ]]; then
        enabler=0;
    fi;
done;
