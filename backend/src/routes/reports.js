const { Router } = require('express');
const oracledb = require('oracledb');

const router = Router();

/**
 * @route   GET /api/reports/compliance-summary
 * @desc    Executes compliance report generation PL/SQL block and returns Compliant/At Risk/Non-Compliant counts
 * @access  Public
 */
router.get('/compliance-summary', async (req, res, next) => {
  const plsqlBlock = `
    DECLARE
      v_compliant_count NUMBER := 0;
      v_at_risk_count NUMBER := 0;
      v_non_compliant_count NUMBER := 0;
      CURSOR cur_factories IS
        SELECT factory_id, compliance_status FROM FACTORY;
      
      -- variables for capturing DBMS_OUTPUT
      v_lines DBMS_OUTPUT.CHARARR;
      v_num_lines INTEGER := 10000;
      v_output CLOB := '';
    BEGIN
      -- 1. Enable DBMS_OUTPUT
      DBMS_OUTPUT.ENABLE(32767);

      -- 2. Run the reports loop calling the package procedure
      FOR r_fac IN cur_factories LOOP
        pkg_reporting.sp_generate_factory_report(r_fac.factory_id);
        IF r_fac.compliance_status = 'Compliant' THEN
          v_compliant_count := v_compliant_count + 1;
        ELSIF r_fac.compliance_status = 'Partially Compliant' THEN
          v_at_risk_count := v_at_risk_count + 1;
        ELSIF r_fac.compliance_status = 'Non-Compliant' THEN
          v_non_compliant_count := v_non_compliant_count + 1;
        END IF;
      END LOOP;
      
      -- Print final summary
      DBMS_OUTPUT.PUT_LINE('SUMMARY: Compliant=' || v_compliant_count || '; At Risk=' || v_at_risk_count || '; Non-Compliant=' || v_non_compliant_count);

      -- 3. Retrieve lines from DBMS_OUTPUT
      DBMS_OUTPUT.GET_LINES(v_lines, v_num_lines);
      
      -- 4. Concatenate lines into a single CLOB
      FOR i IN 1..v_num_lines LOOP
        v_output := v_output || v_lines(i) || CHR(10);
      END LOOP;
      
      -- 5. Return the full output in the bind variable
      :output := v_output;
    END;
  `;

  let connection;
  try {
    connection = await oracledb.getConnection();
    const result = await connection.execute(
      plsqlBlock,
      {
        output: { type: oracledb.STRING, dir: oracledb.BIND_OUT, maxSize: 100000 }
      }
    );

    const outputText = result.outBinds.output || '';
    const match = outputText.match(/SUMMARY:\s*Compliant=(\d+);\s*At\s*Risk=(\d+);\s*Non-Compliant=(\d+)/i);
    
    if (match) {
      const compliant = parseInt(match[1], 10);
      const atRisk = parseInt(match[2], 10);
      const nonCompliant = parseInt(match[3], 10);
      
      res.json({
        compliant,
        atRisk,
        nonCompliant,
        rawOutput: outputText
      });
    } else {
      res.status(500).json({
        error: 'Failed to parse compliance summary from PL/SQL DBMS_OUTPUT',
        rawOutput: outputText
      });
    }
  } catch (err) {
    next(err);
  } finally {
    if (connection) {
      try {
        await connection.close();
      } catch (cErr) {
        console.error('Error closing connection:', cErr.message);
      }
    }
  }
});

module.exports = router;
