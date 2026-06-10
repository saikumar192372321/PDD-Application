import fs from 'fs';
import ExcelJS from 'exceljs';
import { fileURLToPath } from 'url';
import path from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function generateExcel() {
    const reportPath = path.join(__dirname, 'report.json');
    const reportData = JSON.parse(fs.readFileSync(reportPath, 'utf8'));

    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet('DAST Security Report');

    sheet.columns = [
        { header: 'Finding', key: 'finding', width: 10 },
        { header: 'Severity', key: 'severity', width: 15 },
        { header: 'Test Category', key: 'test_category', width: 20 },
        { header: 'Method', key: 'method', width: 10 },
        { header: 'Endpoint', key: 'endpoint', width: 35 },
        { header: 'Role Tested', key: 'role', width: 15 },
        { header: 'Status Code', key: 'status', width: 15 },
        { header: 'Expected Status', key: 'expected_status', width: 18 },
        { header: 'Details / Note', key: 'note', width: 60 },
        { header: 'Response Time (ms)', key: 'response_time_ms', width: 20 },
        { header: 'Timestamp', key: 'timestamp', width: 25 }
    ];

    sheet.getRow(1).font = { bold: true };

    reportData.forEach(row => {
        let excelRow = sheet.addRow(row);
        
        // Highlight findings
        if (row.finding) {
            excelRow.getCell('finding').value = '⚠️ YES';
            excelRow.getCell('finding').font = { color: { argb: 'FFFF0000' }, bold: true };
            
            if (row.severity === 'Critical') {
                excelRow.getCell('severity').font = { color: { argb: 'FFFF0000' }, bold: true };
            } else if (row.severity === 'High') {
                excelRow.getCell('severity').font = { color: { argb: 'FFFFA500' }, bold: true };
            }
        } else {
            excelRow.getCell('finding').value = 'No';
            excelRow.getCell('finding').font = { color: { argb: 'FF008000' } }; // Green
        }
    });

    const outPath = path.join(__dirname, 'DAST_Report.xlsx');
    await workbook.xlsx.writeFile(outPath);
    console.log(`Excel report successfully generated at ${outPath}`);
}

generateExcel().catch(console.error);
