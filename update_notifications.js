const fs = require('fs');
const filePath = "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\services\\notification_service.dart";
let content = fs.readFileSync(filePath, 'utf8');

content = content.replace("await _firebaseMessaging.subscribeToTopic('all_assets');", "// await _firebaseMessaging.subscribeToTopic('all_assets'); // Disabled to prevent broadcast notifications on new service/equipment");
content = content.replace("print('Subscribed to all_assets topic');", "// print('Subscribed to all_assets topic');");

fs.writeFileSync(filePath, content);
