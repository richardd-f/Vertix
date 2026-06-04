#!/bin/bash

# Exit immediately if any command fails
set -e

FILE="Vertix.xcodeproj/project.pbxproj"

# 1. Check if file exists
if [ ! -f "$FILE" ]; then
    echo "Error: $FILE not found!"
    exit 1
fi

echo "Starting project cleanup..."

# 2. Use perl with error checking
# The '||' handles cases where perl might fail (e.g., regex error)
perl -i.bak -pe '
    undef $/; 
    s/[ \t]*[A-F0-9]+ \/\* Pods_VertixTests\.framework in Frameworks \*\/,\n//g;
    s/[ \t]*[A-F0-9]+ \/\* Pods_VertixTests\.framework in Frameworks \*\/ = \{isa = PBXBuildFile;[^\n]+\};\n//g;
    s/[ \t]*[A-F0-9]+ \/\* Pods_VertixTests\.framework \*\/ = \{isa = PBXFileReference;[^\n]+\};\n//g;
    s/[ \t]*[A-F0-9]+ \/\* Pods_VertixTests\.framework \*\/,\n//g;
' "$FILE" || { echo "Perl script failed!"; exit 1; }

echo "Cleanup completed successfully."
