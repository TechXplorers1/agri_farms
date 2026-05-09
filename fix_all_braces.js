const fs = require('fs');
const files = [
    "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\book_workers_screen.dart",
    "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\book_transport_detail_screen.dart",
    "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\book_service_detail_screen.dart",
    "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\edit_registered_item_screen.dart",
    "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\book_equipment_detail_screen.dart"
];

files.forEach(filePath => {
    let content = fs.readFileSync(filePath, 'utf8');
    content = content.replace(/\}\s*\}\s*\} catch \(e\) \{/g, "}\n    } catch (e) {");
    fs.writeFileSync(filePath, content);
});
