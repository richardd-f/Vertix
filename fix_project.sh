#!/bin/bash
PBXPROJ="Vertix.xcodeproj/project.pbxproj"

# Remove Pods_VertixTests.framework from Frameworks build phase
# Find the line with the UUID and remove it from the files list
python3 - <<'PYTHON'
import re

with open("Vertix.xcodeproj/project.pbxproj", "r") as f:
    content = f.read()

# Remove the PBXBuildFile entry for Pods_VertixTests.framework
content = re.sub(r'\s*[A-F0-9]+ /\* Pods_VertixTests\.framework in Frameworks \*/ = \{isa = PBXBuildFile;[^\n]+\};\n', '\n', content)

# Remove the reference in the Frameworks build phase files list
content = re.sub(r'\s*[A-F0-9]+ /\* Pods_VertixTests\.framework in Frameworks \*/,\n', '', content)

with open("Vertix.xcodeproj/project.pbxproj", "w") as f:
    f.write(content)

print("Patched Pods_VertixTests.framework from Frameworks build phase")
PYTHON
