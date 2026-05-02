const fs = require('fs');
const filePath = "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\upload_item_screen.dart";
let content = fs.readFileSync(filePath, 'utf8');

content = content.replace(/if \(mounted\) \{\s*UiUtils\.showCenteredToast\(context, 'Location detected: \$village, \$district'\);\s*\}\s*\}\s*\} catch \(e\) \{/, "if (mounted) {\n        UiUtils.showCenteredToast(context, 'Location detected: $village, $district');\n      }\n    } catch (e) {");

fs.writeFileSync(filePath, content);
