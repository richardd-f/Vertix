import re

with open("Vertix.xcodeproj/project.pbxproj", "r") as f:
    content = f.read()

# Remove from Frameworks build phase files list
content = re.sub(r'[ \t]*[A-F0-9]+ /\* Pods_VertixTests\.framework in Frameworks \*/,\n', '', content)

# Remove the PBXBuildFile entry
content = re.sub(r'[ \t]*[A-F0-9]+ /\* Pods_VertixTests\.framework in Frameworks \*/ = \{isa = PBXBuildFile;[^\n]+\};\n', '', content)

# Remove the PBXFileReference entry for Pods_VertixTests.framework
content = re.sub(r'[ \t]*[A-F0-9]+ /\* Pods_VertixTests\.framework \*/ = \{isa = PBXFileReference;[^\n]+\};\n', '', content)

# Remove from any PBXGroup children list
content = re.sub(r'[ \t]*[A-F0-9]+ /\* Pods_VertixTests\.framework \*/,\n', '', content)

with open("Vertix.xcodeproj/project.pbxproj", "w") as f:
    f.write(content)

print("Done")
