import re

with open('lib/screens/peminjaman_page.dart', 'r') as f:
    content = f.read()

# Remove the second _showStudentDetails
content = re.sub(r'  void _showStudentDetails\(String nim\).*?\}\n', '', content, flags=re.DOTALL)

with open('lib/screens/peminjaman_page.dart', 'w') as f:
    f.write(content)
