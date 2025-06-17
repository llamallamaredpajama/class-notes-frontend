#!/usr/bin/env python3
import re

# Read the project file
with open('class-notes-frontend.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Remove the proto file from build sources if it exists
lines = content.split('\n')
filtered_lines = []
for line in lines:
    # Skip lines that reference subscription.proto in build sources
    if 'subscription.proto' in line and ('PBXBuildFile' in line or 'Sources' in line):
        print(f"Removing line: {line.strip()}")
        continue
    filtered_lines.append(line)

content = '\n'.join(filtered_lines)

# Write back
with open('class-notes-frontend.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print('Fixed project configuration - removed proto file from build sources') 