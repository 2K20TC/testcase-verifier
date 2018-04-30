#!/bin/sh
# Copyright 2018, Training Cell MEC

CC=cc
VERSION="0.1"
HELP_TEXT="Usage: $0 [-c CC ] [ -s SOLUTION_NAME ] [-d PATH] [-h] PROBLEM"

root_path="$(pwd)"
solution_name="solution.c"
tests_dirname="tests"
output_dirname="output"
problem_name=

help() {
	echo "$HELP_TEXT"
	exit 0
}

error_exit() {
	echo "critical error: $1"
	exit 1
}

while [ $# != 0 ]; do
	case "$1" in
		-h) help ;;
		-c) CC="$2" ; shift ;;
		-d) root_path="$2" ; shift ;;
		-s) solution_name="$2" ; shift ;;
		-*) ;;
		*) problem_name="$1" ;;
	esac
	shift
done

[ -z "$problem_name" ] && error_exit "no problem specified"

output_path="${root_path}/${output_dirname}"
solution_path="${root_path}/${problem_name}/${solution_name}"
testcase_path="${root_path}/${problem_name}/${tests_dirname}"

# scratch directory
if [ ! -d "$output_path" ]; then
	mkdir "$output_path" ||
		error_exit "directory creation failed"
fi
find "$output_path" -maxdepth 1 -type f -delete ||
	error_exit "directory operation failed"

# build the source
$CC -o "${output_path}/bin" "$solution_path" ||
	error_exit "compilation failed"

# verify the output
for cs in $(find "$testcase_path" -maxdepth 1 -iname 'in*.txt'\
	-type f -exec basename "{}" \;)
do
	# extract n, n as in nth testcase
	op_n=$(echo $cs | sed 's/in\(.\)\.txt/\1/')

	"${output_path}/bin" <"${testcase_path}/in${op_n}.txt"\
		>"${output_path}/op${op_n}.txt"

	# extract first 40 chars from shasum output, then compare (cmp)
	# byte-by-byte the first 40 bytes
	cat "${output_path}/op${op_n}.txt" | shasum | cut -d ' ' -f 1 |
		cmp -s -n 40 "${testcase_path}/op${op_n}_hashed.txt" - &&
		echo "test case ${op_n} passed" || echo "test case ${op_n} failed"
done

# cleanup
rm -r "$output_path" ||
       error_exit "directory operation failed"	
